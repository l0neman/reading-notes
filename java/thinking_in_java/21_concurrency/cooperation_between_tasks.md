# 线程之间的协作

- [wait 与 notifyAll](#wait-与-notifyAll)
- [错失的信号](#错失的信号)
- [notify 和 notifyAll](#notify-和-notifyAll)
- [生产者与消费者](#生产者与消费者)

## wait 与 notifyAll

`wait` 方法可以使当前线程处于等待状态，此时线程将被挂起，直到某个条件发生改变。可以使用 `notify` 或 `notifyAll` 方法唤醒线程。

`wait` 方法和 `notifyAll` 方法均为 `Object` 的方法，而且它们必须在 `synchronized` 块中被调用，并且是在这个对象上同步的，否则将发生运行时异常 `IlleagalMonitorStateException`，可这样在同步块中进行操作。

```java
synchronized(target) {
  target.notifyAll();
}
```

与 `sleep` 不同 `wait` 方法将会释放锁，还有一种可以传入时间的 `wait` 方法，使用它将只会被挂起一段时间。

下面是一个开关门的例子，门将重复开关（不断输出 `open,close,open,close ...`）的动作，直到线程停止。

```java
static final class Door {
  private boolean isOpen = false;

  public synchronized void open() {
    System.out.println("open");
    isOpen = true;
    notifyAll();
  }

  public synchronized void close() {
    System.out.println("close");
    isOpen = false;
    notifyAll();
  }

  public synchronized void waitOpen() throws InterruptedException {
    // 等待开门状态。
    while (!isOpen) { wait(); }
  }

  public synchronized void waitClose() throws InterruptedException {
    // 等待关门状态。
    while (isOpen) { wait(); }
  }
}

static final class Open implements Runnable {
  private Door door;

  public Open(Door door) {
    this.door = door;
  }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        door.open();
        TimeUnit.MILLISECONDS.sleep(200);
        door.waitClose();
      }
    } catch (InterruptedException e) {
      System.out.println("open task interrupted.");
    }
  }
}

static final class Close implements Runnable {
  private Door door;

  public Close(Door door) {
    this.door = door;
  }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        door.waitOpen();
        door.close();
        TimeUnit.MILLISECONDS.sleep(300);
      }
    } catch (InterruptedException e) {
      System.out.println("close task interrupted.");
    }
  }
}
```

```java
Door door = new Door();
Open open = new Open(door);
Close close = new Close(door);
ExecutorService exec = Executors.newCachedThreadPool();

// 启动关门任务。
exec.execute(close);

try {
  TimeUnit.MILLISECONDS.sleep(20);
} catch (InterruptedException e) {
  System.out.println("sleep interrupted.");
}

// 启动开门任务。
exec.execute(open);

// 4 秒后终止。
try {
  TimeUnit.SECONDS.sleep(4);
} catch (InterruptedException e) {
  System.out.println("sleep interrupted.");
}

// 中断所有线程。
exec.shutdownNow();
```

## 错失的信号

在对 `wait` 和 `notify/notifyAll` 使用不当时，可能造成死锁，考虑以下情况。

```java
// Thread 1.
synchronized (monitor) {
   condition = false;
   monitor.notifyAll();
}

...
// Thread 2.
while (condition) {
  synchronized (monitor) {
    monitor.wait();
  }
}
```

当 Thread 1 是想要唤醒 Thread 2 的挂起状态的，但是以上的写法可能使 Thread 2 在刚进入 `while(condition)` 中时，线程切换到 Thread 1，此时 Thread 1 在 Thread 2 的 `wait` 之前执行了 `nofityAll`，那么 Thread 2 将会错过这次唤醒，导致死锁。

Thread 2 正确的写法应该如下：

```java
// Thread 2.
synchronized (monitor) {
  while (condition) {
    monitor.wait();
  }
}
```

这样的话，就防止了 `notify` 在 `wait` 之前调用产生的问题，如果 Thread 1 先执行，那么 `condition` 将被赋值，此时 Thread 2 将无法进入循环。 

## notify 和 notifyAll

`nofity` 只能唤醒同一时刻在对象上挂起的其中一个线程，对于 `notifyAll` 来说是一种优化，但必须保证唤醒的是对的线程，否则就应该使用 `notifyAll` ，`notifyAll` 可唤醒同一时刻在对象上挂起的所有线程。

```java
static final class Target {

  private synchronized void waitMe(int id) {
    try {
      System.out.println(id + " wait.");
      wait();
      System.out.println(id + " run.");
    } catch (InterruptedException e) {
      System.out.println(id + " wait interrupted.");
    }
  }
}

...
Target target = new Target();
ExecutorService exec = Executors.newCachedThreadPool();

for (int i = 0; i < 3; i++) {
  final int ii = i;
  exec.execute(new Runnable() {
    @Override public void run() {
      target.waitMe(ii);
    }
  });
}

try {
  TimeUnit.MILLISECONDS.sleep(500);
} catch (InterruptedException e) {
  System.out.println("sleep interrupted.");
}

synchronized (target) {
  target.notify();
}

try {
  TimeUnit.MILLISECONDS.sleep(500);
} catch (InterruptedException e) {
  System.out.println("sleep interrupted.");
}

exec.shutdownNow();
```

上面依次挂起了 3 个线程，然后通知线程唤醒，最后发送中断信号。

如果调用了 `notify`，那么其中一个线程将被唤醒，其他两个只能被中断。可能输出：

```
0 wait.
1 wait.
2 wait.
0 wait interrupted.
1 run.
2 wait interrupted.
```

而使用 `notifyAll` 所有线程都将被唤醒。输出：

```
0 wait
1 wait
2 wait
0 run.
1 run.
2 run.
```

需要注意的是，在调用对象的 `notify/nofityAll` 方法时只能唤醒在此对象锁上被挂起的线程。

## 生产者与消费者

使用蛋糕店模型模拟简单生产者和消费者模型，蛋糕店做出蛋糕后等待配送，配送员送完后等待蛋糕店做新蛋糕。

```java
static final class Cake {
  private int id;

  private Cake(int id) { this.id = id; }
}

/**
 * 蛋糕店
 */
static final class CakeShop implements Runnable {
  private Cake cake;
  private static int sId = 1;
  private final Maker maker = new Maker(this);
  private final Courier courier = new Courier(this);
  private final ExecutorService exec = Executors.newCachedThreadPool();


  private synchronized void makeCake() {
    this.cake = new Cake(sId);
    System.out.println("make cake " + sId);
    sId++;
  }

  private synchronized Cake getCake() { return cake; }

  private synchronized void giveCake() { this.cake = null; }

  private void stop() { exec.shutdownNow(); }

  @Override public void run() {
    exec.execute(maker);
    exec.execute(courier);
  }
}

/**
 * 糕点师
 */
static final class Maker implements Runnable {

  private final CakeShop cakeShop;

  private Maker(CakeShop cakeShop) { this.cakeShop = cakeShop; }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        // 等待配送。
        synchronized (this) {
          while (cakeShop.getCake() != null) {
            wait();
          }
          System.out.println("maker start.");
        }
        // 制造蛋糕。
        TimeUnit.MILLISECONDS.sleep(500);
        cakeShop.makeCake();

        int cakeId = cakeShop.getCake().id;

        // 通知配送员配送。
        System.out.println("maker ok.");
        synchronized (cakeShop.courier) {
          cakeShop.courier.notify();
        }

        // 做完第 10 个蛋糕后停止。
        if (cakeId == 10) {
          cakeShop.stop();
          return;
        }
      }
    } catch (InterruptedException e) {
      System.out.println("cake stop interrupted.");
    }
  }
}

/**
 * 配送员
 */
static final class Courier implements Runnable {
  private final CakeShop cakeShop;

  private Courier(CakeShop cakeShop) { this.cakeShop = cakeShop; }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        // 配送蛋糕。
        if (cakeShop.getCake() != null) {
          TimeUnit.MILLISECONDS.sleep(400);
          cakeShop.giveCake();
          System.out.println("courier ok.");

          // 通知糕点师做蛋糕。
          synchronized (cakeShop.maker) {
            cakeShop.maker.notify();
          }
        }
        // 等待做出新蛋糕。
        synchronized (this) {
          while (cakeShop.getCake() == null) {
            wait();
          }
          System.out.println("courier start.");
        }
      }
    } catch (InterruptedException e) {
      System.out.println("courier interrupted.");
    } finally {
      // 处理好最后一单。
      if (cakeShop.getCake() != null) {
        cakeShop.giveCake();
        System.out.println("courier ok.");
      }
    }
  }
}

...
// 开始。
new CakeShop().run();
```

输出：

```
maker start.
make cake 1
maker ok.
courier start.
courier ok.
...
maker start.
make cake 10
maker ok.
courier start.
courier interrupted.
courier ok.
```

注意：其中使用 `while` 而不是 `if` 的原因是为了防止其他地方可能使用 `notifyAll` 导致的错误唤醒，而此时条件并没有得到满足，从而出错。使用 `while` 在条件不满足时依然可以回到挂起状态。

```java
while (condition) {
    synchronized (this) {
        wait();
    }
}
```

## 使用显示的 Lock 和 Condition 对象

## 生产者-消费者和队列

## BlockingQueue

## 使用管道进行输入输出


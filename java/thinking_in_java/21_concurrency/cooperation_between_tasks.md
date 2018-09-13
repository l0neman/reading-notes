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

  public Open(Door door) { this.door = door; }

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

  public Close(Door door) { this.door = door; }

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

使用蛋糕店模型模拟简单生产者和消费者模型，糕点师做出蛋糕后等待配送，配送员送完后等待蛋糕店做新蛋糕。

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

## 使用显式的 Lock 和 Condition 对象

使用 java 提供的并发工具 `Lock` 和 `Condition` 对象可替代 `Object` 的 `wait/notifyAll` 方法，其中 `Condition` 对象可使用 `await()` 方法将线程挂起，使用 `singalAll` 替代 `notifyAll` 唤醒线程。

使用`Lock` 和 `Condition` 重写开门的例子。

```java
static final class Door {

  private boolean isOpen = false;
  private Lock lock = new ReentrantLock();
  private Condition condition = lock.newCondition();

  public void open() {
    lock.lock();
    isOpen = true;
    try {
      condition.signalAll();
    } finally {
      lock.unlock();
    }
  }

  public void close() {
    lock.lock();
    isOpen = false;
    try {
      condition.signalAll();
    } finally {
      lock.unlock();
    }
  }

  public void waitOpen() {
    lock.lock();
    try {
      while (!isOpen) {
        condition.await();
      }
    } catch (InterruptedException e) {
      System.out.println("open wait interrupted.");
    } finally {
      lock.unlock();
    }
  }

  private void waitClose() {
    lock.lock();
    try {
      while (isOpen) {
        condition.await();
      }
    } catch (InterruptedException e) {
      System.out.println("close wait interrupted.");
    } finally {
      lock.unlock();
    }
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
        TimeUnit.MILLISECONDS.sleep(300);
        door.open();
        System.out.println("open the door.");
        door.waitClose();
      }
    } catch (InterruptedException e) {
      System.out.println("open interrupted.");
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
        TimeUnit.MILLISECONDS.sleep(400);
        door.close();
        System.out.println("close the door.");
      }
    } catch (InterruptedException e) {
      System.out.println("close interrupted.");
    }
  }
}

...
ExecutorService exec = Executors.newCachedThreadPool();
Door door = new Door();

exec.submit(new Open(door));
exec.submit(new Close(door));

try {
  TimeUnit.SECONDS.sleep(3);
} catch (InterruptedException e) {
  System.out.println("sleep interrupted.");
}

exec.shutdownNow();
```

## 生产者-消费者和队列

相对于 `wait/notify` 方法实现的简单生产者消费者模式，java 提供了更高级的同步阻塞队列 `java.concurrent.BlockingQueue`，可以使用它的 `LinkedBlockingQueue` 或 `ArrayBlockingQueue` 实现类。在出队列时，如果队列内没有元素，那么当前访问线程将被挂起。同步队列更加可靠，适合处理大量元素。

```java
static final class Cake {
  private int id;

  public Cake(int id) { this.id = id; }
}

static final class CakeShop implements Runnable {
  private BlockingQueue<Cake> cakeQueue = new LinkedBlockingDeque<>(10);
  private ExecutorService exec = Executors.newCachedThreadPool();
  private Maker maker = new Maker(this);
  private Courier courier = new Courier(this);
  private static int sId = 1;

  public synchronized int cakeNum() {
    return sId;
  }

  public int getCakeSize() {
    return cakeQueue.size();
  }

  public void makeCake() {
    try {
      synchronized (this) {
        System.out.println("make cake " + sId);
        cakeQueue.put(new Cake(sId++));
      }
    } catch (InterruptedException e) {
      System.out.println("put cake interrupted.");
    }
  }

  public Cake giveCake() {
    try {
      return cakeQueue.take();
    } catch (InterruptedException e) {
      System.out.println("give cake interrupted.");
    }
    return null;
  }

  public void stop() {
    exec.shutdownNow();
  }

  @Override public void run() {
    exec.submit(maker);
    exec.submit(courier);
  }
}

static final class Maker implements Runnable {
  private final CakeShop cakeShop;

  public Maker(CakeShop cakeShop) { this.cakeShop = cakeShop; }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        TimeUnit.MILLISECONDS.sleep(200);
        cakeShop.makeCake();
        if (cakeShop.cakeNum() == 11) {
          cakeShop.stop();
          return;
        }
      }
    } catch (InterruptedException e) {
      System.out.println("maker interrupted.");
    }
  }
}

static final class Courier implements Runnable {
  private final CakeShop cakeShop;

  public Courier(CakeShop cakeShop) { this.cakeShop = cakeShop; }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        TimeUnit.MILLISECONDS.sleep(200);
        final Cake cake = cakeShop.giveCake();
        if (cake != null) {
          System.out.println("give cake " + cake.id + " ok.");
        }
      }
    } catch (InterruptedException e) {
      System.out.println("courier interrupted.");
    } finally {
      // 处理剩余的蛋糕。
      while (cakeShop.getCakeSize() != 0) {
        final Cake cake = cakeShop.giveCake();
        if (cake != null) {
          System.out.println("give last cake " + cake.id + " ok.");
        }
      }
    }
  }
}

...
new CakeShop().run();
```

## 使用管道进行 I/O 操作

java 提供了管道 IO `PipedWriter` 和 `PipedReader`，可使用它们在多线程之间进行输出输出操作。其中 `PipedReader` 与普通 IO 不同，它是可被中断的。

```java
static final class Sender implements Runnable {

  private final PipedWriter pw;

  public Sender(PipedWriter pw) {
    this.pw = pw;
  }

  @Override public void run() {
    char a = 'a';
    try {
      while (!Thread.interrupted() && a < 'z') {
        TimeUnit.MILLISECONDS.sleep(200);
        pw.write(a++);
        System.out.println("send " + (char) (a - 1));
      }
    } catch (InterruptedException e) {
      System.out.println("sender interrupted.");
    } catch (IOException e) {
      System.out.println("sender exception.");
    }
  }
}

static final class Receiver implements Runnable {

  private final PipedReader pr;

  public Receiver(PipedWriter pw) {
    try {
      this.pr = new PipedReader(pw);
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        char a = (char) pr.read();
        System.out.println("receive " + a);
      }
    } catch (IOException e) {
      System.out.println("receiver InterruptedIOException." + e.getMessage());
    }
  }
}

...
ExecutorService exec = Executors.newCachedThreadPool();

final PipedWriter pw = new PipedWriter();
exec.submit(new Sender(pw));
exec.submit(new Receiver(pw));

try {
  TimeUnit.SECONDS.sleep(2);
} catch (InterruptedException e) {
  System.out.println("sleep interrupted.");
}

exec.shutdownNow();
```


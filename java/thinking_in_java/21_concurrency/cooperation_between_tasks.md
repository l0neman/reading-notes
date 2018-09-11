# 线程之间的协作

- [wait 与 notifyAll](#wait-与-notifyAll)

## wait 与 notifyAll

`wait` 方法可以使当前线程处于等待状态，此时线程将被挂起，直到某个条件发生改变，可以使用 `notify` 或 `notifyAll` 方法唤醒线程。

`wait` 方法和 `notifyAll` 方法均为 `Object` 的方法，而且它们必须在 `synchronized` 块中被调用，并且是在这个对象上同步的，否则将发生运行时异常 `IlleagalMonitorStateException`，可在同步块中进行操作。

```java
synchronized(target) {
  target.notifyAll();
}
```

与 `sleep` 不同 `wait` 方法将会释放锁，还有一种可以传入时间的 `wait` 方法，它将只会被挂起一段时间。

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

## 生产者与消费者

## 使用显示的 Lock 和 Condition 对象

## 生产者-消费者和队列

## BlockingQueue

## 使用管道进行输入输出


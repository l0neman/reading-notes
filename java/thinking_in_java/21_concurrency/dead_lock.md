# 死锁

考虑下面的示例，有两个工人需要操作平台的两个按钮，`leftButton` 和 `rightButton` ，一个工人需要首先持有一个按钮，然后再持有另一个按钮，操作一段时间后释放两个按钮，然后等待一段时间后再次操作，另一个工人也需要这样做，工人在持有按钮之前，如果有人占用了按钮，那么他将等待，直至另一个人释放后，自己才能持有。

下面用代码来模拟，工人 1 首先持有 `leftButton` 然后持有 `rightButton`，另一个工人首先持有 `rightButton` 然后持有 `leftButton` ，中间有随机的休息时间时间。

```java
private static final class Target {
  private boolean leftButton = false;
  private boolean rightButton = false;

  public synchronized void release() {
    this.leftButton = false;
    this.rightButton = false;
  }
}

/* 工人 1 */
private static final class Worker1 implements Runnable {
  private final Target target;
  private Random random = new Random();

  public Worker1(Target target) { this.target = target; }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

        synchronized (target) {
          /* 请求 leftButton */
          while (target.leftButton) {
            target.wait();
          }
          System.out.println("work 1 hold left.");
          target.leftButton = true;
        }

        TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

        synchronized (target) {
          /* 请求 rightButton */
          while (target.rightButton) {
            target.wait();
          }
          System.out.println("work 1 hold right.");
          target.rightButton = true;

          TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

          target.release();
          target.notifyAll();
        }
        System.out.println("work 1 ok.");
      }
    } catch (InterruptedException e) {
      System.out.println("work 1 interrupted.");
    }
  }
}

/* 工人 2 */
private static final class Worker2 implements Runnable {
  private final Target target;
  private Random random = new Random();

  public Worker2(Target target) { this.target = target; }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

        synchronized (target) {
          /* 请求 rightButton */
          while (target.rightButton) {
            target.wait();
          }
          System.out.println("work 2 hold left.");
          target.rightButton = true;
        }

        TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

        synchronized (target) {
          /* 请求 leftButton */
          while (target.leftButton) {
            target.wait();
          }
          System.out.println("work 2 hold right.");
          target.leftButton = true;

          TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

          target.release();
          target.notifyAll();

          System.out.println("work 2 ok.");
        }
      }
    } catch (InterruptedException e) {
      System.out.println("work 2 interrupted.");
    }
  }
}
```

以上的代码将会造成死锁，当工人 1 持有了 `leftButton`，此时请求 `rightButton`，而此时 `rightButton` 可能被工人 2 持有，那么工人 1 等待 `rightButton` 的时候，工人 2 也在等待 `leftButton` 导致谁也不会释放锁，最终形成死锁。

## 形成死锁的条件

形成死锁的条件需要满足以下所有四个条件：

1. 互斥条件，使用的资源中至少有一个是不能共享的，上面的是两个按钮，不能同时被一个人持有。
2. 至少有一个任务它必须持有一个资源而且正在等待一个正在被另一个任务持有的资源，这里工人持有一个按钮时还需要判断等待另一个按钮。
3. 资源不能被任务抢占，任务把释放当做普通事件，这里工人不会强制持有按钮，需要等待另一个人释放。
4. 必须有循环等待，工人等待一个按钮释放，而另一个工人在等待另一个资源，形成循环。

## 解决死锁的办法

因为死锁的形成需要满足以上 4 个条件，而前三个条件一般的线程安全的程序都需具有，这里最容易的办法就是破坏最后一个条件，这里的话，只需要让第二个工人首先请求持有 `rightButton` 即可解决，即两个任务按照相同的顺序请求资源，这是不存在工人持有一个按钮再去等待另一个按钮的情况。

```java
private static final class Target {
  private boolean leftButton = false;
  private boolean rightButton = false;

  public synchronized void release() {
    this.leftButton = false;
    this.rightButton = false;
  }
}

/* 工人 1 */
private static final class Worker1 implements Runnable {
  private final Target target;
  private Random random = new Random();

  public Worker1(Target target) { this.target = target; }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

        synchronized (target) {
          /* 请求 leftButton */
          while (target.leftButton) {
            target.wait();
          }
          System.out.println("work 1 hold left.");
          target.leftButton = true;
        }

        TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

        synchronized (target) {
          /* 请求 rightButton */
          while (target.rightButton) {
            target.wait();
          }
          System.out.println("work 1 hold right.");
          target.rightButton = true;

          TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

          target.release();
          target.notifyAll();
        }
        System.out.println("work 1 ok.");
      }
    } catch (InterruptedException e) {
      System.out.println("work 1 interrupted.");
    }
  }
}

/* 工人 2 */
private static final class Worker2 implements Runnable {
  private final Target target;
  private Random random = new Random();

  public Worker2(Target target) { this.target = target; }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

        synchronized (target) {
          /* 请求 leftButton */
          while (target.leftButton) {
            target.wait();
          }
          System.out.println("work 2 hold left.");
          target.leftButton = true;
        }

        TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

        synchronized (target) {
          /* 请求 rightButton */
          while (target.rightButton) {
            target.wait();
          }
          System.out.println("work 2 hold right.");
          target.rightButton = true;

          TimeUnit.MILLISECONDS.sleep(random.nextInt(500));

          target.release();
          target.notifyAll();

          System.out.println("work 2 ok.");
        }
      }
    } catch (InterruptedException e) {
      System.out.println("work 2 interrupted.");
    }
  }
}
```


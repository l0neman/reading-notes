# 新类库中的组件

- [CountDownLatch](#CountDownLatch)
- [CyclicBarrier](#CyclicBarrier)

## CountDownLatch

 它可以用来同步一个或多个任务，初始化时指定一个初始数值，每个任务执行完毕计数减一，在计数不为 0 时，当前线程将会阻塞，直到 0 继续，通常也可用它来把异步代码转换为同步代码。

这个计数是一次性的不能重置计数器。

```java
ExecutorService exec = Executors.newCachedThreadPool();
CountDownLatch latch = new CountDownLatch(3);
Random random = new Random();

for (int i = 0; i < 3; i++) {
  int finalI = i;
  exec.execute(new Runnable() {
    @Override public void run() {
      try {
        TimeUnit.MILLISECONDS.sleep(random.nextInt(500));
        /* 计数减一 */
        latch.countDown();
        System.out.println(finalI + " is ok.");
      } catch (InterruptedException e) {
        System.out.println("interrupted.");
      }
    }
  });
}
try {
  /* 阻塞，直到计数为 0(所有任务执行完毕) */
  latch.await();
} catch (InterruptedException e) {
  System.out.println("await interrupted.");
}
System.out.println("all ok.");
```

执行结果：

```
1 is ok.
2 is ok.
0 is ok.
all ok.
```

## CyclicBarrier

可以使用它来同步多个任务，在任务都完成时统一再进行下一个步骤，和 `CountDownLatch` 不同的是，它可以被重置，默认在计数为0 时自动重置，在构造方法可插入一个在每次任务开始前都会执行的栅栏操作。

下面是一个示例，每次执行三个任务，任务的时间随机，并在它们都执行完时打印最长时间的任务，持续 4 秒。

```java
static final class TimeTask implements Runnable {
  private int time;
  private int id;
  private Random random;
  private CyclicBarrier cyclicBarrier;

  public TimeTask(Random random, int id, CyclicBarrier cyclicBarrier) {
    this.id = id;
    this.random = random;
    this.cyclicBarrier = cyclicBarrier;
  }

  public synchronized int getTime() { return time; }

  @Override public void run() {
    try {
      while (!Thread.interrupted()) {
        synchronized (this) {
          this.time = this.random.nextInt(500);
        }
        TimeUnit.MILLISECONDS.sleep(getTime());
        System.out.println("task " + id + " time is " + time);
        cyclicBarrier.await();
      }
    } catch (InterruptedException e) {
      System.out.println(id + " task interrupt");
    } catch (BrokenBarrierException e) {
      throw new RuntimeException(e);
    }
  }
}

...
ExecutorService exec = Executors.newCachedThreadPool();
Random random = new Random();
final int count = 3;
TimeTask[] tasks = new TimeTask[3];

CyclicBarrier cyclicBarrier = new CyclicBarrier(count,
    new Runnable() {
      @Override public void run() {
        TimeTask task = tasks[0].time > tasks[1].time ? tasks[0] : tasks[1];
        task = task.time > tasks[2].time ? task : tasks[2];
        // 每次打印出最长时间的任务。
        System.out.println("===== the longest time is task" + task.id);
      }
    });

for (int i = 0; i < count; i++) {
  exec.execute(tasks[i] = new TimeTask(random, i, cyclicBarrier));
}

try {
  TimeUnit.SECONDS.sleep(4);
} catch (InterruptedException e) {
  System.out.println("main sleep interrupted.");
} finally {
  // 结束运行。
  exec.shutdownNow();
}
```

输出：

```
task 2 time is 196
task 1 time is 437
task 0 time is 453
===== the longest time is task0
task 1 time is 189
task 0 time is 272
task 2 time is 304
===== the longest time is task2
...
2 task interrupt
0 task interrupt
1 task interrupt
```

## DelayQueue

它是一个阻塞队列，内部防止带有延期的任务，必须等到任务的到期时间才能从中取走任务执行，否则将阻塞，任务需要实现 `Delayed` 接口。

```java
static final class DelayedTask implements Delayed {
  private long triggerTime;
  private int id;

  public DelayedTask(int delayInMillis, int id) {
    this.id = id;
    triggerTime = System.nanoTime() + TimeUnit.NANOSECONDS.convert(
        delayInMillis, TimeUnit.MILLISECONDS
    );
  }

  public long getTriggerTime() { return triggerTime; }

  @Override public long getDelay(TimeUnit unit) {
    return unit.convert(triggerTime - System.nanoTime(), TimeUnit.NANOSECONDS);
  }

  @Override public int compareTo(Delayed o) {
    DelayedTask oTask = (DelayedTask) o;
    return (int) (triggerTime - oTask.triggerTime);
  }
}

...
DelayQueue<DelayedTask> delayedTasks = new DelayQueue<>();
Random random = new Random();
for (int i = 1; i <= 3; i++) {
  final int delayInMillis = random.nextInt(500) + 200;
  delayedTasks.put(new DelayedTask(delayInMillis, i));
  System.out.println("add delayed task " + i + " delay " + delayInMillis);
}

new Thread(new Runnable() {
  @Override public void run() {
    while (!Thread.interrupted()) {
      try {
        final DelayedTask task = delayedTasks.take();
        System.out.println("execute " + task.id);
      } catch (InterruptedException e) {
        System.out.println("take interrupted.");
      }
    }
  }
}).start();
```

结果，按照超时时间。

```
add delayed task 1 delay 411
add delayed task 2 delay 291
add delayed task 3 delay 625
execute 2
execute 1
execute 3
```


# Java 基本线程机制

- [并发的多面性](#并发的多面性)
- [创建任务](#创建任务)
- [Thread 类](#Thread-类)
- [使用 Executor](#使用-Executor)
- [从任务产生返回值](#从任务产生返回值)
- [休眠](#休眠)
- [优先级](#优先级)
- [让步](#让步)
- [后台线程](#后台线程)
- [线程编码方式](#线程编码方式)
- [加入线程](#加入线程)
- [捕获异常](#捕获异常)

## 并发的多面性

- 并发可以提升单处理器上执行的程序性能，虽然并发的开销很大，因为增加了上下文切换的代价，但是在一些场景并发处理是非常有效的，比如执行 I/O 时阻塞。
- ## 并发对于处理单处理器系统上的事件驱动编程很有效。

。。。

## 创建任务

使用 `Runnable` 接口可创建一个任务，任务将为线程的执行做准备。

```java
Runnable task = new Runnable() {
  @Override public void run() {
    // do something.  
  }
};

task.run() // 直接执行任务。
```

## Thread 类

可将 `Runnable` 创建的任务通过构造器传入 `Thread` 类，即可使用 `Thread` 类的 `start()` 方法提交任务到线程执行，此时任务将在新线程执行。

```java
Runnable task = new Runnable() {
  @Override public void run() {
    // do something.
  }
};

Thread t = new Thread(task);
t.start();
```

## 使用 Executor

`java.util.concurrent` 包中的 `Executor` 执行器将为你管理线程，它提供了一个间接层，简化了并发编程。

```java
ExecutorService exec = Executors.newCachedThreadPool();
exec.execute(new Runnable() {
  @Override public void run() {
    // do something.
  }
});
exec.shutdown();
```

除了 `CachedThreadPool`，还可使用 `FixedThreadPool` 和 `SingleThreadPool`

```java
FixedThreadPool  // 固定数量的线程池。
SingleThreadPool // 单线程池，提交任务将排队执行。
```

## 从任务产生返回值

使用线程池的 `submit` 方法可提交 `Callable` 任务，与 `Runnable` 任务不同，它将产生返回值。

```java
ExecutorService exec = Executors.newCachedThreadPool();
Callable<String> task = new Callable<String>() {
  @Override public String call() throws Exception {
    // do something.
    return "value";
  }
};
Future<String> future = exec.submit(task);

try {
  future.get(); // 在执行结束后获取返回值。
} catch (InterruptedException | ExecutionException e) {
  System.out.println(e);
}finally {
  exec.shutdown();
}
```

使用 `Future` 的 `get` 方法获取返回值，它会阻塞，也可以使用带有超时的 `get` 方法，或使用 `isDone` 询问任务是否执行完毕。

```java
try {
  future.get(2, TimeUnit.SECONDS); // 超时将抛出异常。
} catch (InterruptedException | ExecutionException | TimeoutException e) {
  System.out.println(e);
} finally {
  exec.shutdown();
}

if(future.isDone()) {
  // do something.
}
```

## 休眠

使用 `sleep` 方法可使线程休眠，此时 cpu 可以切换到另一个线程执行。

```java
Thread t = new Thread(new Runnable() {
  @Override public void run() {
    // do something.
    try {
      // Thread.sleep(100);
      /* 也可使用 TimeUnit 更加细粒度的控制 sleep 时间。 */
      TimeUnit.MILLISECONDS.sleep(100);
    } catch (InterruptedException e) {
      System.out.println(e);
    }
  }
});
t.start();
```

## 优先级

可以修改线程的优先级，优先级高的线程将优先被调度器执行，一般情况下都使用默认的优先级。

可使用 `setPriority` 方法设置线程优先级，JDK 提供了 10 个优先级，但是它对操作系统的线程优先级映射支持可能没有那么好，所以一般只用 `MAX_PRIORITY`，`NORM_PRIORITY` 和 `MIN_PRIORITY` 三种优先级。

```java
Thread t = new Thread(new Runnable() {
  @Override public void run() {
    /* 需要在 run 方法里设置优先级 */
    Thread.currentThread().setPriority(Thread.MAX_PRIORITY);
    // do something.
  }
});
t.start();
```

## 让步

使用 `yield` 方法可以建议调度器将 CPU 时间让出来给其它具有相同优先级的线程执行。

```java
final Random random = new Random();
Thread t = new Thread(new Runnable() {
  @Override public void run() {
    while (!Thread.interrupted()) {
      // 使用让步控制线程的分布情况。
      if(random.nextInt(2) == 0) {
        Thread.yield();
      }
      // do something.
    }
  }
});
t.start();
```

## 后台线程

使用 `setDaemon` 方法可将线程设置为后台线程，当所有的非后台线程都结束时，所有的后台线程都会被杀死。

```java
Thread t = new Thread(new Runnable() {
  @Override public void run() {
    // do something.
  }
});
/* 必须在线程开始之前设置。 */
t.setDaemon(true);
t.start();
```

使用 `isDaemon` 方法判断一个线程是否是后台线程。

```java
t.isDaemon();
```

在一个后台线程中创建的子线程，如果没有显式指定后台线程，那么默认为后台线程。

## 线程编码方式

除了实现 `Runnable` 来创建任务提交给线程执行外，还可以使用其他编码方式来启动线程。

- 继承 `Thread` 类，实现其 `run` 方法。

```java
Thread t = new Thread() {
  @Override public void run() {
    // do something.
  }
};
t.start();
```

- 实现 `Runnable` 并自我管理。

```java
public final class SelfManaged implements Runnable {
  private Thread mThread = new Thread(this);

  public SelfManaged() {
    mThread.start();
  }

  @Override public void run() {
    // do something.
  }
}

....
Runnnable task = new SelfManaged();
```

- 内部线程类。

```java
public final class InnerThread {
  public InnerThread() { new Inner(); }

  private static final class Inner implements Runnable {

    private Thread thread = new Thread(this);

    public Inner() { thread.start(); }

    @Override public void run() {
      // do something.
    }
  }
}

...
InnerThread innerThread = new InnerThread();
```

## 加入线程

使用 `join` 方法可以在当前线程加入一个线程，当你在某个线程调用另一个线程 t 的 `join` 方法时，本线程此时将被挂起，直到线程 t 执行完毕才能恢复。

```java
Thread task1 = new Thread(new Runnable() {
  @Override public void run() {
		// do something in task1.
  }
});

Thread task2 = new Thread(new Runnable() {
  @Override public void run() {
    task1.start();
    try {
      task1.join();
    } catch (InterruptedException e) {
      System.out.println("task 1 interrupted.");
    }
  }
});

task2.start();
```

还可以在 `join` 方法中指定一个超时时间，当时间内加入的线程未完成时，也可以及时返回本线程。

```java
task.join(200);
```

`join` 方法可被中断，需要对可能出现的异常进行处理。

## 捕获异常

线程内可能出现抛出异常的情况，当异常抛出时，它会被传递到 `run` 方法的外部，如果直接进行异常的捕捉是没有用的。

```java
try {
  new Thread(new Runnable() {
    @Override public void run() {
      throw new RuntimeException();
    }
  }).start();
} catch (Exception e) {
  e.printStackTrace(); // 捕捉不到异常。
}
```

使用 `setUncaughtExceptionHandeler` 为线程设置一个异常处理器，它是一个 `Thread.UncaughtExceptionHandler` 对象，可以在里面处理线程中的异常。

```java
Thread task = new Thread(new Runnable() {
  @Override public void run() {
    throw new RuntimeException("ex");
  }
});
task.setUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {
  @Override public void uncaughtException(Thread t, Throwable e) {
    /* print "Thread-0 exception: java.lang.RuntimeException: ex". */
    System.out.println(t.getName() + " exception: " + e);
  }
});
task.start();
```

可以用在线程工厂中，配合线程池使用。

```java
Thread.UncaughtExceptionHandler myHandler = new Thread.UncaughtExceptionHandler() {
  @Override public void uncaughtException(Thread t, Throwable e) {
    System.out.println(t.getName() + " exception: " + e);
  }
};

ThreadFactory threadFactory = new ThreadFactory() {
  @Override public Thread newThread(Runnable r) {
    Thread t = new Thread(r);
    t.setUncaughtExceptionHandler(myHandler);
    return t;
  }
};

ExecutorService exec = Executors.newCachedThreadPool(threadFactory);
```

如果在需要在每个地方都使用类似的异常处理器，你也可以指定一个全局的静态处理器。

```java
Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {
  @Override public void uncaughtException(Thread t, Throwable e) {
    System.out.println(t.getName() + " exception: " + e);
  }
});
```
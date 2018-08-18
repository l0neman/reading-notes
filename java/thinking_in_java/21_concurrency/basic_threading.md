# Java 基本线程机制

## 并发的多面性

- 并发可以提升单处理器上执行的程序性能，虽然并发的开销很大，因为增加了上下文切换的代价，但是在一些场景并发处理是非常有效的，比如执行 I/O 时阻塞。
- 并发对于处理单处理器系统上的事件驱动编程很有效。

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


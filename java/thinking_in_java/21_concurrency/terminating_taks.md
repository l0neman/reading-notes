# 终结任务

- [在阻塞时终结](#在阻塞时终结)
- [进入阻塞状态](#进入阻塞状态)
- [中断](#中断)
- [被互斥时阻塞](#被互斥时阻塞)
- [检查中断](#检查中断)

## 在阻塞时终结

- 线程状态

1. 新建（New）：线程被创建，它将短暂处于这种状态，此时线程已经有资格获取 CPU 时间，之后调度器可能把它变为就绪状态或阻塞状态。
2. 就绪（Runnable）：此时调度器一旦给线程分配时间片，那么它就处于运行状态。在任意时刻，线程可能处于运行或不运行的状态，但不是阻塞或死亡。
3. 阻塞（Blocked）：线程处于可以运行的状态，但某个条件阻止它的运行，此时线程被阻塞，调度器将不会给线程分配任何 CPU 时间，直到线程重新进入就绪状态，它才有可能重新执行操作。
4. 死亡（Dead）：此时线程被终止，它将不再时可被调度的，不会再得到任何 CPU 时间，通常是已经从 `run` 方法返回或被中断。

## 进入阻塞状态

- 线程进入阻塞状态的原因

1. 调用 `sleep(millis)` 方法使线程进入休眠状态，线程在这段指定的时间内不会运行。
2. 调用 `wait()` 使线程挂起，直到线程被 `notify()` 或 `nofityAll()` 释放而进入就绪状态。（使用 `java.util.concurrent` 类中的 `await()` 方法和 `signal(), signalAll()` 方法作用相同）
3. 任务在等待 I/O 操作完成。
4. 线程试图获得一个同步方法的锁，但是此时锁已被其它线程占用。

## 中断

当一个线程处于阻塞状态时，可使用 `interrupt()` 方法对线程进行中断，中断时，线程将抛出 `InterruptedException` 异常，需要注意在线程中断时正确的回收资源。

```java
Thread t = new Thread(new Runnable() {
  @Override public void run() {
    try {
      TimeUnit.MILLISECONDS.sleep(200);
    } catch (InterruptedException e) {
      System.out.println("thread interrupted.");
    }
  }
});
t.start();
/* 中断。 */
t.interrupt();
```

注意对于正在获取 `synchronized` 锁的线程和正在执行 I/O 操作的线程无法中断。对于 I/O 操作可以使用关闭阻塞的资源的方式来停止执行。

```java
private InputStream socketInput;

...
Thread t = new Thread(new Runnable() {
  @Override public void run() {
    try {
      socketInput = new Socket("localhost", 8080).getInputStream();
      socketInput.read(); // I/O 阻塞。
    }
    catch (IOException ignore) {}
    finally {
      if (socketInput != null) {
        try { socketInput.close(); }
        catch (IOException ignore) {}
      }
    }
  }
});
t.start();
if (socketInput != null) {
    socketInput.close(); // 关闭资源。
}
```

使用 `Executor` 时，并且调用 `shutdownNow()` 方法关闭线程池时，线程池将会给所有的已启动的线程发送 `interrupt` 信号。

```java
ExecutorService exec = Executors.newCachedThreadPool();
exec.execute(new Runnable() {
  @Override public void run() {
    try {
      TimeUnit.MILLISECONDS.sleep(200);
    } catch (InterruptedException e) {
      System.out.println("thread interrupted.");
    }
  }
});
/* 将会中断所有线程。 */
exec.shutdownNow();
```

使用 `Executor` 的 `submit()` 方法而不是 `executor()` 时，它将返回一个 `Future` 对象，使用它的 `cancel()` 方法并传递 `true` 时，将调用对应线程的 `interrupt()` 方法对线程进行中断。

```java
ExecutorService exec = Executors.newCachedThreadPool();
final Future<?> future = exec.submit(new Runnable() {
  @Override public void run() {
    try {
      TimeUnit.MILLISECONDS.sleep(200);
    } catch (InterruptedException e) {
      System.out.println("thread interrupted.");
    }
  }
});
try {
  TimeUnit.MILLISECONDS.sleep(1);
} catch (InterruptedException e) {
  System.out.println("main sleep interrupted.");
}finally {
  future.cancel(true);
}
```

NIO 中增加了对中断的支持，被中断的 I/O 将自动响应中断。

```java
Thread t = new Thread(new Runnable() {
  @Override public void run() {
    try {
      socketChannel = SocketChannel.open(
          new InetSocketAddress("localhost", 8080));
      socketChannel.read(ByteBuffer.allocate(1));
    }
    catch (ClosedByInterruptException e) { // 被中断时抛出。
      System.out.println("ClosedByInterruptException");
    }
    catch (AsynchronousCloseException e) { // 在其他线程被关闭时抛出。
      System.out.println("AsynchronousCloseException");
    }
    catch (IOException ignore) {}
    finally {
      if (socketChannel != null) {
        try { socketChannel.close(); }
        catch (IOException ignore) {}
      }
    }
  }
});
t.start();
t.interrupt();
//  if (socketChannel != null) {
//    try { socketChannel.close(); }
//    catch (IOException ignore) {}
//  }
```

## 被互斥时阻塞

当你访问一个已被 `synchronized` 关键字加锁的方法时，如果此时它已被其他线程锁定 ，那么线程会处于阻塞状态，且无法响应中断。

```java
private static final class Target {
  public void funcA() {
    synchronized (this) {
      try {
        System.out.println("funcA");
        TimeUnit.SECONDS.sleep(1);
      } catch (InterruptedException e) {
        System.out.println("funcA interrupted.");
      }
    }
  }

  public void funcB() {
    synchronized (this) {
      System.out.println("funcB");
    }
  }
}

...
Target target = new Target();
Thread a = new Thread(new Runnable() {
  @Override public void run() {
    target.funcA();
  }
});
a.start();

/* 需要等待 a 释放锁。 */
Thread b = new Thread(new Runnable() {
  @Override public void run() {
    target.funcB();
  }
});
b.start();
/* 此时无法中断。 */
b.interrupt();
```

使用 `ReentrantLock` 在阻塞时具有可被中断的能力。

```java
private static final class Target {
  private ReentrantLock lock = new ReentrantLock();

  public void funcA() {
    lock.lock();
    try {
      System.out.println("funcA");
      TimeUnit.SECONDS.sleep(1);
    } catch (InterruptedException e) {
      System.out.println("funcA interrupted.");
    } finally {
      lock.unlock();
    }
  }

  public void funcB() {
    try {
      /* 此时阻塞可被中断。 */
      lock.lockInterruptibly();
      System.out.println("funcB");
    } catch (InterruptedException e) {
      System.out.println("thread b interrupted.");
    }
  }
}

...
Target target = new Target();
Thread a = new Thread(new Runnable() {
  @Override public void run() {
    target.funcA();
  }
});
a.start();

/* 需要等待 a 释放锁。 */
Thread b = new Thread(new Runnable() {
  @Override public void run() {
    Thread.yield();
    target.funcB();
  }
});
b.start();
/* 此时可以被中断。 */
b.interrupt();
```

## 检查中断

除了在线程可被中断时主动退出，在没有任何阻塞产生的时候想要退出线程，你可以使用 `interrupt()` 方法为线程设置中断标志，然后通过 `Thread.interrupted()` 方法检查中断标志，当它检测到中断标志时，会清空中断标志，所以，如果需要再次检查中断，需要把它的返回值保存起来，使用这种方式终止线程时还要注意资源的清除。

```java
Thread t = new Thread(new Runnable() {
 @Override public void run() {
   /* 检查中断标志。 */
   while (!Thread.interrupted()){
     Closeable test = new Test();
     // do something...
     try {
       TimeUnit.MILLISECONDS.sleep(100);
     } catch (InterruptedException e) {
       System.out.println("sleep interrupted");
     }finally { // 回收资源。
       try { test.close(); }
       catch (IOException ignore) {}
     }
   }
 }
});
t.start();
t.interrupt(); // 中断线程。
```


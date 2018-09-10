# 线程共享资源

- [错误的共享资源](#错误的共享资源)
- [解决共享资源问题](#解决共享资源问题)
- [使用显式的 Lock 对象](#使用显式的-Lock-对象)
- [原子性与易变性](#原子性与易变性)
- [原子类](#原子类)
- [临界区](#临界区)
- [在其他对象上同步](#在其他对象上同步)
- [线程本地存储](#线程本地存储)

## 错误的共享资源

当多个线程同时共同访问一个同一个资源时，可能出现和预期不一致的结果。

考虑一个每次自增 2 次的计数器，使用 2 个线程同时访问它的值，理想情况下，两个线程每次输出的数字都是相差两个 2 的，然而事实却不是这样。

```java
/* 计数器。 */
private static final class NextInt {
  private int count = 0;

  private int next() { // 自增 2 次。
    ++count;
    ++count;
    return count;
  }
}

...
// main() =>
final NextInt nextInt = new NextInt();
ExecutorService exec = Executors.newCachedThreadPool();

final Runnable task = new Runnable() {
    @Override public void run() {
        for (int i = 0; i < 50; i++) {
            final int next = nextInt.next();
            System.out.println(Thread.currentThread().getName() + ": " + next);
            Thread.yield(); // 使线程平均分布
        }
    }
};

// 两个线程分别访问 50 次。
exec.execute(task);
exec.execute(task);
```

理想情况下输出为 `2, 4, 6, 8, 10, 12, ... 200` ，而实际则可能出现 `2, 4, 6, 8, 8, 10, ...` 这种情况。

因为 `next` 方法中执行的逻辑不是原子的，在一个线程执行 `next` 的同时，另一个线程在累加过程中执行 `next` 方法，导致 `count` 的数值出现和预料结果不一致的情况。

## 解决共享资源问题

当一个线程正在访问一个资源时，另一个线程如果同时访问就可能出现数据不一致的情况，导致结果和预期不同，如果一个线程访问一个资源时，此时锁定这个资源，不允许其他线程访问，在自己访问完毕后再交给其他线程访问，就可以避免资源不一致的情况。

使用 `synchronized` 关键字可以对方法进行锁定，当一个线程访问此方法时，另一个线程将不可同时访问同一对象中的这个方法，直到前一个线程访问方法退出后，这个线程才能访问。当你要访问的资源包含在这个锁定的方法内，那么问题就可以被解决。

上一个计数器的问题只需要为 `next` 方法添加 `synchronized` 关键字就可完全解决 `count` 不一致的问题。

```java
private static final class NextInt {
  private int count = 0;

  // 可被当前访问线程锁定的方法，内部逻辑只受当前线程影响。
  private synchronized int next() {
    ++count;
    ++count;
    return count;
  }
}
```

那么两个线程同时访问结果打印出来自然一定是 `2, 4, 6, 8, 10, 12, 14, 200`。

当你用 `synchronized` 修饰一个 `static` 方法，那么同步将在类的范围内作用。

- 如果你正在写一个变量，它可能接下来将被另一个线程读取，或者正在读取一个上一次已经被另一个线程写过的变量，那么你必须使用同步，并且，读写线程度必须用相同的监视锁同步。

## 使用显式的 Lock 对象

使用 `java.util.concurrent` 包中的 `Lock` 对象提供的线程互斥机制可比 `synchronized` 关键字更加灵活，你需要手动创建并管理锁的锁定和释放。

```java
// Lock 版的计数器。
private static final class NextInt {
  private int count;
  private Lock lock = new ReentrantLock();

  private int next() {
      lock.lock();
      try {
          count++;
          count++;
          return count;
      } finally {
          lock.lock();
      }
  }
}
```

一定要以 `try...finally` 这种形式保证锁的释放。

一般情况下推荐使用更简洁的 `synchronized` 关键字，当有特殊需求时，比如想要处理获取锁失败的情况。或者尝试在一段时间内获取锁，可使用 `Lock` 类。

```java
Lock lock = new ReentrantLock();
/* 尝试获取锁。 */
final boolean isLock = lock.tryLock();
try{
  // do something.
}finally {
  if(isLock) { // 如果获取了锁，那么释放。
    lock.unlock();
  }
}
```

在一段时间内尝试获得锁。

```java
Lock lock = new ReentrantLock();
boolean isLock;
try {
  /* 尝试在 2 秒内获取锁。 */
  isLock = lock.tryLock(2, TimeUnit.SECONDS);
} catch (InterruptedException e) {
  throw new RuntimeException(e);
}
try {
  // do something.
} finally {
  if (isLock) { // 如果获取了锁，那么释放。
    lock.unlock();
  }
}
```

## 原子性与易变性

对于除了 `long` 和 `double` 之外的基本类型的简单操作（直接读写）来说，可以保证它们时原子的，在 JVM 中，`long` 和 `double` 可能被分为两个 32  的数字进行执行读写操作，可能导致多个线程同时访问时出现不一致的情况。

使用 `volatile` 关键字修饰 `long` 和 `double` 类型可获得原子性，同时 `volatile` 可保证变量的可见性，对变量的读写操作都将直接反应到主存，而一般情况下，每个线程将访问自己的线程本地缓存。

以下操作在 Java 中不是原子操作，所以需要对它们进行同步处理。

```java
i++;
i+=2;
```

## 原子类

Java 提供了一些原子类，它们在某些现代处理器上是可获取的，并且是机器级的原子性。在涉及性能调优的方面很有用。

```
AtomicInteger, AtomicLong, AtomicReference...
```

使用原子类来改善计数器。

```java
private static final class NextInt {
  private AtomicInteger count = new AtomicInteger(0);

  // 原子操作，累加 2。
  private int next() {
    return count.addAndGet(2);
  }
}
```

## 临界区

使用 `synchronized` 关键字可以将某个对象作为锁建立临界区，对于临界区内的代码，当前线程需要获取到被锁定的对象锁后，才能执行。

```java
private static final class Test {
  private void test() {
    synchronized (this) {
      // do something.
    }
    ...
  }
}
```

通过对代码的局部同步控制，相当于整个同步方法，多线程并发访问的效率得到了提升。

## 在其他对象上同步

除了使用临界区对一个类的对象本身进行锁定，还可以对其他对象进行锁定，但必须保证相关线程都是在同一个锁定对象上执行的。这提高了同步的灵活性，在一个类中，可存在多种不同的对象同步。

```java
private static final class Test {
    private final Object lock1 = new Object();
    private final Object lock2 = new Object();

    private void test() {
      synchronized (lock1) {
        // do something.
      }
      synchronized (lock2){
        // do something.
      }
      ...
    }
  }
```

## 线程本地存储

解决线程共享资源的另一个方法是为每个线程都生成一个对应的变量，它们具有相同的变化。

使用 `java.lang.ThreadLocal` 类，可为每个线程绑定一个对象数据，使用它的 `get` 方法获取当前线程保存的原始对象副本，使用 `set` 方法将对象设置到对应的线程本地存储中。

```java
// 计数器。
private static final class NextInt {
  private ThreadLocal<Integer> count = new ThreadLocal<Integer>() {
    @Override protected Integer initialValue() { return 0; }
  };

  /* 每个线程只能访问自己那份数据 */  
  private int next() {
    int n = count.get();
    n++;
    n++;
    count.set(n);
    return count.get();
  }
}
```


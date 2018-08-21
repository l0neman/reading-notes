# 线程共享资源

- [错误的访问资源](#错误的访问资源)

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
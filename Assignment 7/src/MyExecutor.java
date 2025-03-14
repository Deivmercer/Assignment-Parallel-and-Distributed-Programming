// Davide Costantini

package paradis.assignment3;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.*;

public class MyExecutor implements ExecutorService {

	private final List<Thread> threads;
	private final BlockingQueue<Runnable> commandQueue;
	private boolean isShutdown;

	public MyExecutor(int threadNumber) {

		commandQueue = new LinkedBlockingQueue<>();
		threads = new ArrayList<>(threadNumber);
		for (int i = 0; i < threadNumber; i++) {
			Thread thread = new Thread(() -> {
				while (!isShutdown || !commandQueue.isEmpty()) {
					try {
						Runnable command = commandQueue.poll(100, TimeUnit.MILLISECONDS);
						if (command != null)
							command.run();
					} catch (InterruptedException e) {
						throw new RuntimeException(e);
					}
				}
			});
			threads.add(thread);
			thread.start();
		}
	}

	@Override
	public void shutdown() {

		isShutdown = true;
	}

	@Override
	public boolean awaitTermination(long timeout, TimeUnit unit) throws InterruptedException {

		long endTime = System.nanoTime() + unit.toNanos(timeout);
		for (Thread thread : threads) {
			long remainingTime = endTime - System.nanoTime();
			if (remainingTime > 0)
				thread.join(unit.toMillis(remainingTime));
			else
				return false;
		}

		return true;
	}

	@Override
	public void execute(Runnable command) {

		if (!isShutdown)
			commandQueue.add(command);
	}

	@Override
	public <T> Future<T> submit(Callable<T> task) {

		throw new UnsupportedOperationException("Not implemented.");
	}

	@Override
	public <T> Future<T> submit(Runnable task, T result) {

		throw new UnsupportedOperationException("Not implemented.");
	}

	@Override
	public Future<?> submit(Runnable task) {

		throw new UnsupportedOperationException("Not implemented.");
	}

	@Override
	public <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks) {

		throw new UnsupportedOperationException("Not implemented.");
	}

	@Override
	public <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit) {

		throw new UnsupportedOperationException("Not implemented.");
	}

	@Override
	public <T> T invokeAny(Collection<? extends Callable<T>> tasks) {

		throw new UnsupportedOperationException("Not implemented.");
	}

	@Override
	public <T> T invokeAny(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit) {

		throw new UnsupportedOperationException("Not implemented.");
	}

	@Override
	public List<Runnable> shutdownNow() {

		throw new UnsupportedOperationException("Not implemented.");
	}

	@Override
	public boolean isShutdown() {

		throw new UnsupportedOperationException("Not implemented.");
	}

	@Override
	public boolean isTerminated() {

		throw new UnsupportedOperationException("Not implemented.");
	}
}

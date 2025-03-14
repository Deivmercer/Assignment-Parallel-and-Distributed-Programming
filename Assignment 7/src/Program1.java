// Davide Costantini

package paradis.assignment3;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.TimeUnit;

public class Program1 {

	final static int NUM_WEBPAGES = 40;
	private static final WebPage[] webPages = new WebPage[NUM_WEBPAGES];
	// [You are welcome to add some variables.]

	private static final ForkJoinPool forkJoinPool = ForkJoinPool.commonPool();
	private static final BlockingQueue<WebPage> downloadedQueue = new ArrayBlockingQueue<>(NUM_WEBPAGES);
	private static final BlockingQueue<WebPage> analyzedQueue = new ArrayBlockingQueue<>(NUM_WEBPAGES);

	// [You are welcome to modify this method, but it should NOT be parallelized.]
	private static void initialize() {
		for (int i = 0; i < NUM_WEBPAGES; i++) {
			webPages[i] = new WebPage(i, "http://www.site.se/page" + i + ".html");
		}
	}

	// [Do modify this sequential part of the program.]
	private static void downloadWebPages() {

		for (WebPage webPage : webPages) {
			forkJoinPool.execute(() -> {
				webPage.download();
				boolean added = downloadedQueue.offer(webPage);
				if (!added)
					System.err.println("Failed to add analyzed WebPage");
			});
		}
	}

	// [Do modify this sequential part of the program.]
	private static void analyzeWebPages() {

		for (int i = 0; i < NUM_WEBPAGES; i++) {
			forkJoinPool.execute(() -> {
				try {
					WebPage webPage = downloadedQueue.take();
					webPage.analyze();
					boolean added = analyzedQueue.offer(webPage);
					if (!added)
						System.err.println("Failed to add analyzed WebPage");
				} catch (InterruptedException e) {
					throw new RuntimeException(e);
				}
			});
		}
	}

	// [Do modify this sequential part of the program.]
	private static void categorizeWebPages() {

		for (int i = 0; i < NUM_WEBPAGES; i++) {
			forkJoinPool.execute(() -> {
				try {
					WebPage webPage = analyzedQueue.take();
					webPage.categorize();
				} catch (InterruptedException e) {
					throw new RuntimeException(e);
				}
			});
		}
		forkJoinPool.shutdown();
	}

	// [You are welcome to modify this method, but it should NOT be parallelized.]
	private static void presentResult() {
		for (int i = 0; i < NUM_WEBPAGES; i++) {
			System.out.println(webPages[i]);
		}
	}

	public static void main(String[] args) {

		// Initialize the list of webpages.
		initialize();

		// Start timing.
		long start = System.nanoTime();

		// Do the work.
		downloadWebPages();
		analyzeWebPages();
		categorizeWebPages();

		try {
			forkJoinPool.awaitTermination(Long.MAX_VALUE, TimeUnit.NANOSECONDS);
		} catch (InterruptedException e) {
			throw new RuntimeException(e);
		}

		// Stop timing.
		long stop = System.nanoTime();

		// Present the result.
		presentResult();

		// Present the execution time.
		System.out.println("Execution time (seconds): " + (stop - start) / 1.0E9);
	}
}

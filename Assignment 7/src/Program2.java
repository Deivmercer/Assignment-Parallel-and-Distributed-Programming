// Davide Costantini

package paradis.assignment3;

import java.util.Arrays;

public class Program2 {

	final static int NUM_WEBPAGES = 40;
	private static final WebPage[] webPages = new WebPage[NUM_WEBPAGES];
	// [You are welcome to add some variables.]

	// [You are welcome to modify this method, but it should NOT be parallelized.]
	private static void initialize() {
		for (int i = 0; i < NUM_WEBPAGES; i++) {
			webPages[i] = new WebPage(i, "http://www.site.se/page" + i + ".html");
		}
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

		Arrays.stream(webPages)
				.parallel()
				.map(page -> {
					page.download();
					return page;
				}).map(page -> {
					page.analyze();
					return page;
				}).map(page -> {
					page.categorize();
					return page;
				}).forEach(System.out::println);

		// Stop timing.
		long stop = System.nanoTime();

		// Present the result.
//		presentResult();

		// Present the execution time.
		System.out.println("Execution time (seconds): " + (stop - start) / 1.0E9);
	}
}

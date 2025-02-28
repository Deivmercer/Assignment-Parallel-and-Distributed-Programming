import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.math.BigInteger;
import java.util.concurrent.locks.ReentrantLock;

public class Factorizer implements Runnable {

	final BigInteger STEP = BigInteger.TWO;
	final BigInteger min;
	final BigInteger max;
	final ReentrantLock flagLock = new ReentrantLock();
	final ReentrantLock factorsLock = new ReentrantLock();
	static BigInteger product = BigInteger.ZERO;
	static BigInteger factor1;
	static BigInteger factor2;
	static boolean found = false;

	public Factorizer(BigInteger min, BigInteger max) {
		this.min = min;
		this.max = max;
	}

	@Override
	public void run() {

		BigInteger number = min;
		while (number.compareTo(max) <= 0) {
			flagLock.lock();
			try {
				if (found)
					break;

				factorsLock.lock();
				try {
					if (product.remainder(number).compareTo(BigInteger.ZERO) == 0) {
						found = true;
						factor1 = number;
						factor2 = product.divide(factor1);
						return;
					}
				} finally {
					factorsLock.unlock();
				}
			} finally {
				flagLock.unlock();
			}
			number = number.add(STEP);
		}
	}

	public static void main(String[] args) {

		System.out.println("Available cores: " + Runtime.getRuntime().availableProcessors());

		int threadNumber;
		if (args.length == 2) {
			product = new BigInteger(args[0]);
			threadNumber = Integer.parseInt(args[1]);
		} else {
			InputStreamReader streamReader = new InputStreamReader(System.in);
			BufferedReader consoleReader = new BufferedReader(streamReader);
			System.out.print("Insert a number: ");
			try {
				String input = consoleReader.readLine();
				product = new BigInteger(input);
				System.out.print("Insert the number of threads: ");
				input = consoleReader.readLine();
				threadNumber = Integer.parseInt(input);
			} catch (IOException e) {
				System.out.println("Could not read from terminal.\n");
				e.printStackTrace();
				return;
			} catch (NumberFormatException e) {
				System.out.println("Value is not a number.\n");
				e.printStackTrace();
				return;
			}
		}

		long start = System.nanoTime();

		if (product.remainder(BigInteger.TWO).compareTo(BigInteger.ZERO) == 0) {
			BigInteger factor2 = product.divide(BigInteger.TWO);
			long stop = System.nanoTime();
			System.out.println("Factor1: 2\nFactor2: " + factor2);
			System.out.println("Execution time (seconds): " + (stop-start)/1.0E9);
			return;
		}

		Factorizer[] factorizers = new Factorizer[threadNumber];
		Thread[] threads = new Thread[threadNumber];
		BigInteger limit = product.sqrt();
		BigInteger split = limit.divide(BigInteger.valueOf(threadNumber));
		BigInteger min = BigInteger.valueOf(3), max = split;
		for (int i = 0; i < threadNumber; i++) {
			System.out.println("Thead[" + i + "]: min = " +  min + "; max = " + max);
			factorizers[i] = new Factorizer(min, max);
			threads[i] = new Thread(factorizers[i]);
			min = max.add(BigInteger.ONE);
			max = max.add(split);
			if (min.remainder(BigInteger.TWO).compareTo(BigInteger.ZERO) == 0)
				min = min.add(BigInteger.ONE);
		}

		for (int i = 0; i < threadNumber; i++)
			threads[i].start();

		try {
			for (int i = 0; i < threadNumber; i++)
				threads[i].join();
		} catch (InterruptedException e) {
			System.out.println("Thread got interrupted.\n");
			e.printStackTrace();
			return;
		}

		long stop = System.nanoTime();

		if (factor1 != null)
			System.out.println("Factor1: " + factor1 + "\nFactor2: " + factor2);
		else
			System.out.println("No factorization possible.");
		System.out.println("Execution time: " + (stop-start)/1.0E9);
	}
}

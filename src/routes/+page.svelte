
<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { supabase } from '#lib/supabase/client.ts';
	import type { Wallet } from '#lib/types.ts';

	let wallets = $state<Wallet[]>([]);
	let walletName = $state('');
	let walletScope = $state<'business' | 'personal'>('business');
	let isLoading = $state(true);
	let isSaving = $state(false);
	let errorMessage = $state('');

	let todayIncome = $state(0);
	let todayExpense = $state(0);

	const businessWallets = $derived(
		wallets.filter((wallet) => wallet.scope === 'business')
	);

	const personalWallets = $derived(
		wallets.filter((wallet) => wallet.scope === 'personal')
	);

	const businessBalance = $derived(
		businessWallets.reduce((total, wallet) => total + Number(wallet.balance), 0)
	);

	const personalBalance = $derived(
		personalWallets.reduce((total, wallet) => total + Number(wallet.balance), 0)
	);

	const isOnboardingComplete = $derived(
		businessWallets.length > 0 && personalWallets.length > 0
	);

	const currencyFormatter = new Intl.NumberFormat('id-ID', {
		style: 'currency',
		currency: 'IDR',
		maximumFractionDigits: 0
	});

	function getLocalDateString(): string {
		const now = new Date();
		const year = now.getFullYear();
		const month = String(now.getMonth() + 1).padStart(2, '0');
		const day = String(now.getDate()).padStart(2, '0');

		return `${year}-${month}-${day}`;
	}

	async function loadWallets() {
		const { data, error } = await supabase
			.from('wallets')
			.select('*')
			.order('created_at', { ascending: true });

		if (error) {
			throw error;
		}

		wallets = data.map((wallet): Wallet => {
			if (wallet.scope !== 'business' && wallet.scope !== 'personal') {
				throw new Error('Invalid wallet scope returned from database.');
			}

			return {
				...wallet,
				scope: wallet.scope
			};
		});
	}

	async function loadTodaySummary() {
		const { data, error } = await supabase
			.from('transactions')
			.select('type, amount')
			.eq('transaction_date', getLocalDateString());

		if (error) {
			throw error;
		}

		todayIncome = data.reduce(
			(total, transaction) =>
				transaction.type === 'income'
					? total + Number(transaction.amount)
					: total,
			0
		);

		todayExpense = data.reduce(
			(total, transaction) =>
				transaction.type === 'expense'
					? total + Number(transaction.amount)
					: total,
			0
		);
	}

	async function loadDashboard() {
		await loadWallets();
		await loadTodaySummary();
	}

	onMount(async () => {
		try {
			const { data, error } = await supabase.auth.getSession();

			if (error) {
				throw error;
			}

			if (!data.session) {
				await goto('/login');
				return;
			}

			await loadDashboard();
		} catch (error) {
			errorMessage =
				error instanceof Error
					? error.message
					: 'Failed to load dashboard.';
		} finally {
			isLoading = false;
		}
	});

	async function handleCreateWallet(event: SubmitEvent) {
		event.preventDefault();

		const name = walletName.trim();

		if (!name) {
			errorMessage = 'Wallet name is required.';
			return;
		}

		errorMessage = '';
		isSaving = true;

		try {
			const { error } = await supabase.from('wallets').insert({
				name,
				scope: walletScope
			});

			if (error) {
				throw error;
			}

			walletName = '';
			await loadWallets();
		} catch (error) {
			errorMessage =
				error instanceof Error
					? error.message
					: 'Failed to create wallet.';
		} finally {
			isSaving = false;
		}
	}

	async function handleSignOut() {
		errorMessage = '';

		const { error } = await supabase.auth.signOut();

		if (error) {
			errorMessage = error.message;
			return;
		}

		await goto('/login');
	}
</script>

<svelte:head>
	<title>Dashboard | Catat Kas</title>
	<meta
		name="description"
		content="Your personal and business finance dashboard."
	/>
</svelte:head>

<main class="min-h-screen bg-slate-50 px-4 py-8 sm:px-6 lg:px-8">
	<div class="mx-auto max-w-4xl">
		<header class="mb-8 flex items-center justify-between">
			<div>
				<h1 class="text-2xl font-bold tracking-tight text-slate-900">
					Catat Kas
				</h1>
				<p class="mt-1 text-sm text-slate-500">
					Your financial overview.
				</p>
			</div>

			<button
				type="button"
				onclick={handleSignOut}
				class="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-white"
			>
				Sign Out
			</button>
		</header>

		{#if isLoading}
			<div class="rounded-xl bg-white p-8 text-center shadow-sm">
				<p class="text-sm text-slate-500">Loading dashboard...</p>
			</div>
		{:else}
			{#if errorMessage}
				<div
					class="mb-6 rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700"
					role="alert"
				>
					{errorMessage}
				</div>
			{/if}

			{#if !isOnboardingComplete}
				<section class="mb-8 rounded-xl border border-amber-200 bg-amber-50 p-5">
					<h2 class="font-semibold text-amber-900">
						Complete Your Onboarding
					</h2>
					<p class="mt-1 text-sm text-amber-800">
						Create at least one Business wallet and one Personal wallet to
						complete your initial setup.
					</p>

					<div class="mt-4 flex flex-wrap gap-2 text-sm">
						<span
							class="rounded-full px-3 py-1 font-medium
								{businessWallets.length > 0
									? 'bg-indigo-100 text-indigo-700'
									: 'bg-white text-slate-600'}"
						>
							Business: {businessWallets.length > 0 ? 'Completed' : 'Required'}
						</span>

						<span
							class="rounded-full px-3 py-1 font-medium
								{personalWallets.length > 0
									? 'bg-emerald-100 text-emerald-700'
									: 'bg-white text-slate-600'}"
						>
							Personal: {personalWallets.length > 0 ? 'Completed' : 'Required'}
						</span>
					</div>
				</section>
			{:else}
				<section class="mb-8">
					<h2 class="mb-4 text-lg font-semibold text-slate-900">
						Balance Overview
					</h2>

					<div class="grid gap-4 sm:grid-cols-2">
						<div
							class="rounded-xl border border-indigo-100 bg-white p-5 shadow-sm"
						>
							<p class="text-sm font-medium text-indigo-600">
								Business Balance
							</p>
							<p class="mt-2 text-2xl font-bold text-slate-900">
								{currencyFormatter.format(businessBalance)}
							</p>
							<p class="mt-1 text-sm text-slate-500">
								{businessWallets.length} wallet(s)
							</p>
						</div>

						<div
							class="rounded-xl border border-emerald-100 bg-white p-5 shadow-sm"
						>
							<p class="text-sm font-medium text-emerald-600">
								Personal Balance
							</p>
							<p class="mt-2 text-2xl font-bold text-slate-900">
								{currencyFormatter.format(personalBalance)}
							</p>
							<p class="mt-1 text-sm text-slate-500">
								{personalWallets.length} wallet(s)
							</p>
						</div>
					</div>
				</section>

				<section class="mb-8">
					<h2 class="mb-4 text-lg font-semibold text-slate-900">
						Today's Transactions
					</h2>

					<div class="grid gap-4 sm:grid-cols-2">
						<div class="rounded-xl bg-white p-5 shadow-sm">
							<p class="text-sm font-medium text-emerald-600">Income</p>
							<p class="mt-2 text-xl font-bold text-slate-900">
								{currencyFormatter.format(todayIncome)}
							</p>
						</div>

						<div class="rounded-xl bg-white p-5 shadow-sm">
							<p class="text-sm font-medium text-red-600">Expense</p>
							<p class="mt-2 text-xl font-bold text-slate-900">
								{currencyFormatter.format(todayExpense)}
							</p>
						</div>
					</div>
				</section>
			{/if}

			<section class="mb-8 rounded-xl bg-white p-5 shadow-sm sm:p-6">
				<h2 class="text-lg font-semibold text-slate-900">
					{isOnboardingComplete ? 'Add Another Wallet' : 'Create Your First Wallets'}
				</h2>

				<p class="mt-1 text-sm text-slate-500">
					Add a wallet for your business or personal finances.
				</p>

				<form onsubmit={handleCreateWallet} class="mt-5 space-y-4">
					<div>
						<label
							for="wallet-name"
							class="mb-1.5 block text-sm font-medium text-slate-700"
						>
							Wallet Name
						</label>

						<input
							id="wallet-name"
							bind:value={walletName}
							type="text"
							maxlength="100"
							placeholder="e.g. Cash, Bank Account"
							required
							class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
						/>
					</div>

					<div>
						<label
							for="wallet-scope"
							class="mb-1.5 block text-sm font-medium text-slate-700"
						>
							Wallet Type
						</label>

						<select
							id="wallet-scope"
							bind:value={walletScope}
							class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
						>
							<option value="business">Business</option>
							<option value="personal">Personal</option>
						</select>
					</div>

					<button
						type="submit"
						disabled={isSaving}
						class="w-full rounded-lg bg-indigo-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto"
					>
						{isSaving ? 'Saving...' : 'Create Wallet'}
					</button>
				</form>
			</section>

			<section class="space-y-6">
				<div>
					<h2 class="mb-3 text-lg font-semibold text-slate-900">
						Business Wallets
					</h2>

					{#if businessWallets.length === 0}
						<p class="rounded-xl bg-white p-5 text-sm text-slate-500 shadow-sm">
							No business wallets yet.
						</p>
					{:else}
						<div class="space-y-3">
							{#each businessWallets as wallet (wallet.id)}
								<div
									class="flex items-center justify-between rounded-xl bg-white p-5 shadow-sm"
								>
									<div>
										<p class="font-medium text-slate-900">{wallet.name}</p>
										<p class="mt-1 text-xs text-indigo-600">Business</p>
									</div>

									<p class="font-semibold tabular-nums text-slate-900">
										{currencyFormatter.format(wallet.balance)}
									</p>
								</div>
							{/each}
						</div>
					{/if}
				</div>

				<div>
					<h2 class="mb-3 text-lg font-semibold text-slate-900">
						Personal Wallets
					</h2>

					{#if personalWallets.length === 0}
						<p class="rounded-xl bg-white p-5 text-sm text-slate-500 shadow-sm">
							No personal wallets yet.
						</p>
					{:else}
						<div class="space-y-3">
							{#each personalWallets as wallet (wallet.id)}
								<div
									class="flex items-center justify-between rounded-xl bg-white p-5 shadow-sm"
								>
									<div>
										<p class="font-medium text-slate-900">{wallet.name}</p>
										<p class="mt-1 text-xs text-emerald-600">Personal</p>
									</div>

									<p class="font-semibold tabular-nums text-slate-900">
										{currencyFormatter.format(wallet.balance)}
									</p>
								</div>
							{/each}
						</div>
					{/if}
				</div>
			</section>
		{/if}
	</div>
</main>


<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { supabase } from '#lib/supabase/client.ts';

	let mode = $state<'sign-in' | 'sign-up'>('sign-in');
	let email = $state('');
	let password = $state('');
	let isLoading = $state(false);
	let errorMessage = $state('');
	let successMessage = $state('');

	onMount(async () => {
		const { data } = await supabase.auth.getSession();

		if (data.session) {
			await goto('/');
		}
	});

	async function handleSubmit(event: SubmitEvent) {
		event.preventDefault();

		errorMessage = '';
		successMessage = '';
		isLoading = true;

		try {
			if (mode === 'sign-up') {
				const { data, error } = await supabase.auth.signUp({
					email,
					password
				});

				if (error) throw error;

				if (data.session) {
					await goto('/');
				} else {
					successMessage =
						'Registration successful. Please check your email to confirm your account.';
				}
			} else {
				const { error } = await supabase.auth.signInWithPassword({
					email,
					password
				});

				if (error) throw error;

				await goto('/');
			}
		} catch (error) {
			errorMessage =
				error instanceof Error
					? error.message
					: 'An unexpected error occurred.';
		} finally {
			isLoading = false;
		}
	}

	async function handleGoogleSignIn() {
		errorMessage = '';
		isLoading = true;

		try {
			const { error } = await supabase.auth.signInWithOAuth({
				provider: 'google',
				options: {
					redirectTo: window.location.origin
				}
			});

			if (error) throw error;
		} catch (error) {
			errorMessage =
				error instanceof Error
					? error.message
					: 'Google sign-in failed.';
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>Sign In | Catat Kas</title>
	<meta
		name="description"
		content="Sign in to manage your personal and business finances."
	/>
</svelte:head>

<main class="flex min-h-screen items-center justify-center bg-slate-50 px-4 py-10">
	<section class="w-full max-w-md rounded-2xl bg-white p-6 shadow-sm sm:p-8">
		<div class="mb-8 text-center">
			<h1 class="text-3xl font-bold tracking-tight text-slate-900">
				Catat Kas
			</h1>

			<p class="mt-2 text-sm text-slate-500">
				Manage your personal and business finances.
			</p>
		</div>

		<div class="mb-6 grid grid-cols-2 rounded-lg bg-slate-100 p-1">
			<button
				type="button"
				class={`rounded-md px-3 py-2 text-sm font-medium transition ${
					mode === 'sign-in'
						? 'bg-white text-slate-900 shadow-sm'
						: 'text-slate-500'
				}`}
				onclick={() => {
					mode = 'sign-in';
					errorMessage = '';
					successMessage = '';
				}}
			>
				Sign In
			</button>

			<button
				type="button"
				class={`rounded-md px-3 py-2 text-sm font-medium transition ${
					mode === 'sign-up'
						? 'bg-white text-slate-900 shadow-sm'
						: 'text-slate-500'
				}`}
				onclick={() => {
					mode = 'sign-up';
					errorMessage = '';
					successMessage = '';
				}}
			>
				Create Account
			</button>
		</div>

		<form onsubmit={handleSubmit} class="space-y-4">
			<div>
				<label for="email" class="mb-1.5 block text-sm font-medium text-slate-700">
					Email Address
				</label>

				<input
					id="email"
					type="email"
					bind:value={email}
					autocomplete="email"
					placeholder="you@example.com"
					required
					class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
				/>
			</div>

			<div>
				<label for="password" class="mb-1.5 block text-sm font-medium text-slate-700">
					Password
				</label>

				<input
					id="password"
					type="password"
					bind:value={password}
					autocomplete={mode === 'sign-in' ? 'current-password' : 'new-password'}
					placeholder="Enter your password"
					minlength="6"
					required
					class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
				/>
			</div>

			{#if errorMessage}
				<p class="rounded-lg bg-red-50 p-3 text-sm text-red-700" role="alert">
					{errorMessage}
				</p>
			{/if}

			{#if successMessage}
				<p class="rounded-lg bg-green-50 p-3 text-sm text-green-700" role="status">
					{successMessage}
				</p>
			{/if}

			<button
				type="submit"
				disabled={isLoading}
				class="w-full rounded-lg bg-indigo-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
			>
				{#if isLoading}
					Please wait...
				{:else if mode === 'sign-in'}
					Sign In
				{:else}
					Create Account
				{/if}
			</button>
		</form>

		<div class="my-6 flex items-center gap-3">
			<div class="h-px flex-1 bg-slate-200"></div>
			<span class="text-xs text-slate-400">OR</span>
			<div class="h-px flex-1 bg-slate-200"></div>
		</div>

		<button
			type="button"
			onclick={handleGoogleSignIn}
			disabled={isLoading}
			class="flex w-full items-center justify-center gap-3 rounded-lg border border-slate-300 px-4 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60"
		>
			<svg
				viewBox="0 0 48 48"
				class="h-5 w-5"
				aria-hidden="true"
			>
				<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5Z"/>
				<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.73 7.18l7.34 5.7c4.29-3.96 7.43-9.8 7.43-17.35Z"/>
				<path fill="#FBBC05" d="M10.53 28.59a14.4 14.4 0 0 1 0-9.18l-7.98-6.19a24 24 0 0 0 0 21.56l7.98-6.19Z"/>
				<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.91-5.8l-7.34-5.7c-2.04 1.37-4.65 2.18-8.57 2.18-6.26 0-11.57-4.22-13.46-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48Z"/>
			</svg>

			Continue with Google
		</button>
	</section>
</main>

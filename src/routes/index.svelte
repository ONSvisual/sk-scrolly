<script>
	import { onMount } from "svelte";
	import { base } from '$app/paths';
	import { goto } from "$app/navigation";

	onMount(() => {
		goto(`${base}/E06000001`);
	});
</script>

<a href="{base}/E06000001">Redirecting...</a>
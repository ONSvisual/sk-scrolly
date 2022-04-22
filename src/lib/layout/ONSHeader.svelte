<script>
  import { themes } from '$lib/config';
	import { getContext } from 'svelte';
	import ONSLogo from "./ONSLogo.svelte";
	
	export let theme = getContext('theme');
	export let filled = true;
	export let center = false;

	let primary = theme == "dark" ? "white" : filled ? "#003c57" : "#222222";
	let secondary = theme == "dark" || filled ? "#a8bd3a" : "#222222";
</script>

<nav style="border-bottom-color: {themes[theme]['muted']}; {filled ? 'background-color: ' +  themes[theme]['background'] + ';' : ''}">
  <div class="col-wide middle" class:center>
		<a href="https://www.ons.gov.uk/">
				<div class="logo">
					<ONSLogo {primary} {secondary}/>
				</div>
		</a>
  </div>
</nav>

<style>
	nav {
		-webkit-box-sizing: border-box;
		box-sizing: border-box;
		position: relative;
		height: 46px;
		margin-bottom: -46px;
		border-bottom: 1px solid #777;
		z-index: 1;
	}
	.logo {
		padding: 5px;
		margin: 0;
		width: 270px;
		line-height: 1;
	}
	a .logo:hover {
		cursor: pointer;
	}
</style>
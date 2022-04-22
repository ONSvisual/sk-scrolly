<script>
  import { base } from "$app/paths";
	import { setContext } from "svelte";
  import "../app.css";
	//import Warning from "$lib/ui/Warning.svelte";
	import ONSHeader from "$lib/layout/ONSHeader.svelte";
	import ONSFooter from "$lib/layout/ONSFooter.svelte";

  // STYLE CONFIG
  // Set theme globally (options are 'light' or 'dark')
  let theme = "light";
  setContext("theme", theme);
</script>

<svelte:head>
  <link rel="icon" href="{base}/favicon.ico" />
	<meta property="og:type" content="website" />
	<meta property="og:image" content="{base}/img/og.png" />
	<meta property="og:image:type" content="image/png" />
</svelte:head>

<!-- <Warning/> -->
<ONSHeader {theme}/>

<main>
  <slot {theme}/>
</main>

<ONSFooter {theme}/>

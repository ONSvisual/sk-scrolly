<script>
  import "../app.css";
  import { base } from "$app/paths";
  import { page } from '$app/stores';
	import { setContext } from "svelte";
  import { analyticsId, analyticsProps } from "$lib/config";
	//import Warning from "$lib/ui/Warning.svelte";
  import AnalyticsBanner from "$lib/layout/AnalyticsBanner.svelte";
	import ONSHeader from "$lib/layout/ONSHeader.svelte";
	import ONSFooter from "$lib/layout/ONSFooter.svelte";

  // STYLE CONFIG
  // Set theme globally (options are 'light' or 'dark')
  let theme = "light";
  setContext("theme", theme);

  // GOOGLE ANALYTICS
  // Settings for page analytics. Values must be shared with <AnalyticsBanner> component
  // 'analyticsId' and 'analyticsProps' are defined in config.js
  let gtag;
</script>

<svelte:head>
  <link rel="icon" href="{base}/favicon.ico" />
	<meta property="og:type" content="website" />
	<meta property="og:image" content="{base}/img/og.png" />
	<meta property="og:image:type" content="image/png" />
</svelte:head>

<!-- <Warning/> -->
<AnalyticsBanner {analyticsId} {analyticsProps} {page} bind:gtag/>
<ONSHeader {theme}/>

<main>
  <slot {theme} {gtag}/>
</main>

<ONSFooter {theme}/>

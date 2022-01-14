<script>
  import { assets } from "$app/paths";
	import { setContext } from "svelte";
  import "../app.css";
	import { themes } from "./config";
	//import Warning from "$lib/ui/Warning.svelte";
	import ONSHeader from "./layout/ONSHeader.svelte";
	import ONSFooter from "./layout/ONSFooter.svelte";

  // STYLE CONFIG
  // Set theme globally (options are 'light' or 'dark')
  let theme = "light";
  setContext("theme", themes[theme]);
</script>

<svelte:head>
  <!-- <link rel="icon" href="{assets}/favicon.png" /> -->
</svelte:head>

<!-- <Warning/> -->
<ONSHeader/>

<slot/>

<ONSFooter/>

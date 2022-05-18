<script context="module">
	export const prerender = true;
	
	import bbox from "@turf/bbox";
  import { base } from "$app/paths";
	import { getData, getTopo, makeDatasets } from "$lib/utils";
	import { colors } from "$lib/config";

	export async function load({ params, fetch }) {
		let data = {};
		let meta = {};

		const keys = ["region", "district"];

		for (const key of keys) {
			let data_raw = await getData(`${base}/data/data_${key}.csv`, fetch);
			let {dataset, metadata} = makeDatasets(data_raw, colors, key);
			data[key] = dataset;
			meta[key] = metadata;
		}
		let geojson = await getTopo(`${base}/data/geo_lad2021.json`, 'geog', fetch);
		let mapbounds = bbox(geojson);

		let selected = params.code.length > 0 ? params.code.replace('/', ''): null; // GSS code for selected district
		let place = null; // Metadata for selected district
		let parent = null; // Gets region code for 'selected'
		let siblings = null; // Array of district GSS codes in 'region'
		
		// Get place data if 'selected' is a valid GSS code
		if (selected && meta.district.lookup[selected]) {
			place = meta.district.lookup[selected];
			parent = place.parent;
			siblings = meta.district.array.filter(d => d.parent == parent).map(d => d.code);
		} else if (selected) {
			selected = null;
		}

		return {
				props: {data, meta, geojson, mapbounds, selected, place, parent, siblings}
		};
	}
</script>

<script>
	export let data, meta, geojson, mapbounds, selected, place, parent, siblings;

	// CORE IMPORTS
	import { getContext, onMount } from "svelte";
	import { getMotion } from "$lib/utils";
	import Header from "$lib/layout/Header.svelte";
	import Section from "$lib/layout/Section.svelte";
	import Media from "$lib/layout/Media.svelte";
	import Scroller from "$lib/layout/Scroller.svelte";
	import Filler from "$lib/layout/Filler.svelte";
	import Divider from "$lib/layout/Divider.svelte";
	import Toggle from "$lib/ui/Toggle.svelte";
	import Arrow from "$lib/ui/Arrow.svelte";
	import Em from "$lib/ui/Em.svelte";
	import Icon from "$lib/ui/Icon.svelte";
	import Select from "$lib/ui/Select.svelte";

	// DEMO-SPECIFIC IMPORTS
	import { goto } from "$app/navigation";
	import { setColors, getBreaks } from "$lib/utils";
	import { units, themes } from "$lib/config";
	import { ScatterChart, LineChart, BarChart } from "@onsvisual/svelte-charts";
	import { Map, MapSource, MapLayer, MapTooltip } from "@onsvisual/svelte-maps";

	// CORE CONFIG (COLOUR THEMES)
	let theme = getContext('theme');
	onMount(() => setColors(themes, theme.name));
	let ssr = true;

	// CONFIG FOR SCROLLER COMPONENTS
	// Config
	const threshold = 0.65;
	// State
	let animation = getMotion(); // Set animation preference depending on browser preference
	let id = {}; // Object to hold visible section IDs of Scroller components
	let idPrev = {}; // Object to keep track of previous IDs, to compare for changes

	// DEMO-SPECIFIC CONFIG
	// Constants
	const mapstyle = "https://bothness.github.io/ons-basemaps/data/style-omt.json";

	// Element bindings
	let map = null; // Bound to mapbox 'map' instance once initialised

	// State
	let hovered; // Hovered district (chart or map)
	let mapHighlighted = []; // Highlighted district (map only)
	let xKey = "area"; // xKey for scatter chart
	let yKey = null; // yKey for scatter chart
	let zKey = null; // zKey (color) for scatter chart
	let rKey = null; // rKey (radius) for scatter chart
	let mapKey = "density"; // Key for data to be displayed on map
	let explore = false; // Allows chart/map interactivity to be toggled on/off
	let showList = false; // Show/hide list of local authorities at end of article

	// FUNCTIONS (INCL. SCROLLER ACTIONS)

	// Functions for chart and map on:select and on:hover events
	function doSelect(e) {
		let selected_new = e.detail.code ? e.detail.code : e.detail.id;
		if (e.detail.feature) fitById(selected); // Fit map if select event comes from map
		goto(`${base}/${selected_new}`, {noscroll: true, keepfocus: true});
	}
	function doHover(e) {
		hovered = e.detail.id;
	}

	// Functions for map component
	function fitBounds(bounds) {
		if (map) {
			map.fitBounds(bounds, {animate: animation, padding: 30});
		}
	}
	function fitById(id) {
		if (geojson && id) {
			let feature = geojson.features.find(d => d.properties.AREACD == id);
			let bounds = bbox(feature.geometry);
			fitBounds(bounds);
		}
	}

	// Actions for Scroller components
	const actions = {
		map: { // Actions for <Scroller/> with id="map"
			map01: () => { // Action for <section/> with data-id="map01"
				fitBounds(mapbounds);
				mapKey = "density";
				mapHighlighted = [];
				explore = false;
			},
			map02: () => {
				fitBounds(mapbounds);
				mapKey = "age_med";
				mapHighlighted = [];
				explore = false;
			},
			map03: () => {
				let hl = data.district.indicators.find(d => d.code == selected);
				fitById(hl.code);
				mapKey = "age_med";
				mapHighlighted = [hl.code];
				explore = false;
			},
			map04: () => {
				fitBounds(mapbounds);
				mapKey = "age_med";
				mapHighlighted = [];
				explore = true;
			}
		},
		chart: {
			chart01: () => {
				xKey = "area";
				yKey = null;
				zKey = null;
				rKey = null;
				explore = false;
			},
			chart02: () => {
				xKey = "area";
				yKey = null;
				zKey = null;
				rKey = "pop";
				explore = false;
			},
			chart03: () => {
				xKey = "area";
				yKey = "density";
				zKey = null;
				rKey = "pop";
				explore = false;
			},
			chart04: () => {
				xKey = "area";
				yKey = "density";
				zKey = "parent_name";
				rKey = "pop";
				explore = false;
			},
			chart05: () => {
				xKey = "area";
				yKey = "density";
				zKey = null;
				rKey = "pop";
				explore = true;
			}
		}
	};

	// Code to run Scroller actions when new caption IDs come into view
	function runActions(key) {
		if (id[key] != idPrev[key] && actions[key][id[key]]) {
			actions[key][id[key]]();
			idPrev[key] = id[key];
		}
	}
	$: id["chart"] && runActions("chart");
	$: id["map"] && runActions("map");
</script>

<svelte:head>
  <title>{place ? `Localised article for ${place.name}` : 'Localised article example'}</title>
	<meta property="og:url" content="{base}{selected ? '/' + selected : ''}" />
  <meta property="og:title" content="{place ? `Localised article for ${place.name}` : 'Localised article example'}" />
	<meta property="og:description" content="This is a description of the page." />
	<meta name="description" content="This is a description of the page." />
</svelte:head>

<Header theme="dark" bgcolor="#206095" bgfixed={true} center={false} short={true}>
	<h1 aria-live="assertive">
		{#if place}
		Localised article for {place.name}
		{:else}
		Localised article template
		{/if}
	</h1>
	<p class="text-big" style="margin-top: 5px">
		This is a short text description of the article that might take up a couple of lines
	</p>
	<p style="margin-top: 20px">
		DD MMM YYYY
	</p>
	<p>
		<Toggle mono={true} bind:checked={animation}>Animation {animation ? 'on' : 'off'}</Toggle>
	</p>
	<div style="margin-top: 55px;">
		<label for="intro-select">
			{#if place}
			Change selected place using the selection box below
			{:else}
			Choose a place using the selection box below
			{/if}
		</label>
		<Select id="intro-select" idKey="code" labelKey="name" items={meta.district.array} value={place} on:select={doSelect} isClearable={false} placeholder="Select a local authority..." darkMode/>
	</div>
	<div style="margin-top: 25px; height: 80px;">
		{#if place}
		<Arrow color="white" {animation}>Scroll to begin</Arrow>
		{/if}
	</div>
</Header>

{#if place}
<Filler theme="lightblue" wide={true} center={false}>
	<p class="text-big">
		This is a large text caption. This template has captions and selections that are specific to <strong>{place.name}</strong>.
	</p>
</Filler>

<Section>
	<h2>This is a section title</h2>
	<p>
		This is a short paragraph of text to demonstrate the standard "medium" column width, font size and line spacing of the template.
	</p>
	<p>
		This is a second short paragraph of text to demonstrate the size of the paragraph spacing in the template.
	</p>
	<blockquote class="text-indent">
		"This is an example of a large embedded quotation."&mdash;A. Person
	</blockquote>
</Section>

<Divider/>

<Section>
	<h2>Embedded charts or media</h2>
	<p>
		Below is an embedded chart. It is set to the same width as the column, "medium" (680px), but could also be "narrow" (540px), "wide" (980px) or "full" width. All options are responsive to fit the width of narrow screens.
	</p>
	<p>
		The chart highlights <Em color="#206095">{meta.region.lookup[parent].name}</Em>, the parent region/nation of <strong>{place.name}</strong>.
	</p>
</Section>

<Media
	col="medium"
	caption="Source: ONS mid-year population estimates."
>
	<div class="chart-sml">
		<BarChart
		  ssr={true}
			data={[...data.region.indicators].sort((a, b) => a.pop - b.pop)}
			xKey="pop" yKey="name" idKey="code"
			color="lightgrey"
			snapTicks={false}
			xFormatTick={d => (d / 1e6)} xSuffix="m"
			height={350} padding={{top: 0, bottom: 15, left: 140, right: 0}}
			highlighted={[parent]} overlayFill colorHighlight="#206095"
			area={false} title="Population by region/nation, 2020"/>
	</div>
</Media>

<Divider/>

<Section>
	<h2>Gridded charts or media</h2>
	<p>
		Below is a grid that can contain charts or any other kind of visual media. The grid can fit in a medium, wide or full-width column, and the media width itself can be narrow (min 200px), medium (min 300px), wide (min 500px) or full-width. The grid is responsive, and will re-flow on smaller screens.
	</p>
</Section>

<Media
	col="wide"
	grid="narrow" gap={20}
	caption="Source: ONS mid-year population estimates."
>
	{#each [...data.region.indicators].sort((a, b) => b.pop - a.pop) as region}
	<div class="chart-sml">
		<LineChart
      ssr={true}
			data={data.region.timeseries}
			xKey="year" yKey="value" zKey="code"
			color="lightgrey"
			lineWidth={1} xTicks={2} snapTicks={false}
			yFormatTick={d => (d / 1e6)} ySuffix="m"
			ssrWidth={180}
			height={200} padding={{top: 0, bottom: 20, left: 30, right: 15}}
			highlighted={[region.code]}
			area={false} title={region.name}/>
	</div>
	{/each}
</Media>

<Divider/>

<Section>
	<h2>This is a dynamic chart section</h2>
	<p>
		The chart below will respond to the captions as you scroll down. The "Scroller" component is
		set to "splitscreen" mode, which means the captions will be on the left side on larger screens.
	</p>
	<p>
		The interactions are via Javascript functions that are called when each caption scrolls into view.
	</p>
</Section>

<Scroller {threshold} bind:id={id['chart']} splitscreen={true}>
	<div slot="background">
		<figure>
			<div class="col-wide height-full">
					<div class="chart">
						<ScatterChart
						    ssr={true}
							height="calc(100vh - 150px)"
							data={data.district.indicators.map(d => ({...d, parent_name: meta.region.lookup[d.parent].name}))}
							colors={explore ? ['lightgrey'] : colors.cat}
							{xKey} {yKey} {zKey} {rKey} idKey="code" labelKey="name"
							r={[3,10]}
							xScale="log"
							xTicks={[10, 100, 1000, 10000]} xFormatTick={d => d.toLocaleString()}
							xSuffix=" sq.km"
							yFormatTick={d => d.toLocaleString()}
							legend={zKey != null} labels
							select={explore} selected={explore ? selected : null} on:select={doSelect}
							hover {hovered} on:hover={doHover}
							highlighted={explore ? siblings : []}
							colorSelect="#206095" colorHighlight="#999" overlayFill
							{animation}/>
					</div>
			</div>
		</figure>
	</div>

	<div slot="foreground">
		<section data-id="chart01">
			<div class="col-medium">
				<p>
					This chart shows the <strong>area in square kilometres</strong> of each local authority district in the UK. Each circle represents one district. The scale is logarithmic.
				</p>
			</div>
		</section>
		<section data-id="chart02">
			<div class="col-medium">
				<p>
					The radius of each circle shows the <strong>total population</strong> of the district.
				</p>
			</div>
		</section>
		<section data-id="chart03">
			<div class="col-medium">
				<p>
					The vertical axis shows the <strong>density</strong> of the district in people per hectare.
				</p>
			</div>
		</section>
		<section data-id="chart04">
			<div class="col-medium">
				<p>
					The colour of each circle shows the <strong>part of the country</strong> that the district is within.
				</p>
			</div>
		</section>
		<section data-id="chart05">
			<div class="col-medium">
				<h3>Select a district</h3>
				<p><label for="chart-select">Use the selection box below or click on the chart to select a district. The chart will also highlight the other districts in the same part of the country.</label></p>
					<p>
						<Select id="chart-select" idKey="code" labelKey="name" items={meta.district.array} value={place} on:select={doSelect} isClearable={false}/>
					</p>
			</div>
		</section>
	</div>
</Scroller>

<Divider/>

<Section>
	<h2>This is a full-width chart demo</h2>
	<p>
		Below is an example of a media grid where the column with is set to "full". This allows for full width images and charts.
	</p>
	<p>

	</p>
</Section>

<Media
	col="full"
	height={600}
	caption='This is an optional caption for the above chart or media. It can contain HTML code and <a href="#">hyperlinks</a>, and wrap onto multiple lines.'
>
	<div class="chart-full">
		<LineChart
		    ssr={true}
			data={data.district.timeseries}
			padding={{left: 50, right: 150, top: 0, bottom: 0}}
			height="500px"
			xKey="year" yKey="value" zKey="code"
			color="lightgrey" lineWidth={1}
			yFormatTick={d => (d/1e6).toFixed(1)} ySuffix="m"
			select {selected} on:select={doSelect}
			hover {hovered} on:hover={doHover}
			highlighted={siblings}
			colorSelect="#206095" colorHighlight="#999"
			area={false} title="Mid-year population by district, 2001 to 2020"
			labels labelKey="name"/>
	</div>
</Media>

<Divider/>

<Section>
	<h2>This is a dynamic map section</h2>
	<p class="mb">
		The map below will respond to the captions as you scroll down. The scroller is not set to splitscreen, so captions are placed over the map on any screen size.
	</p>
</Section>

<Scroller {threshold} bind:id={id['map']}>
	<div slot="background">
		<figure>
			<div class="col-full height-full">
				<Map style={mapstyle} bind:map interactive={false} location={{bounds: mapbounds}}>
					<MapSource
					  id="lad"
					  type="geojson"
					  data={geojson}
					  promoteId="AREACD"
					  maxzoom={13}>
					  <MapLayer
					  	id="lad-fill"
							idKey="code"
							colorKey={mapKey + "_color"}
					  	data={data.district.indicators}
					  	type="fill"
							select {selected} on:select={doSelect} clickIgnore={!explore}
							hover {hovered} on:hover={doHover}
							highlight highlighted={mapHighlighted}
					  	paint={{
					  		'fill-color': ['case',
					  			['!=', ['feature-state', 'color'], null], ['feature-state', 'color'],
					  			'rgba(255, 255, 255, 0)'
					  		],
					  		'fill-opacity': 0.7
					  	}}>
								<MapTooltip content={
									hovered ? `${meta.district.lookup[hovered].name}<br/><strong>${data.district.indicators.find(d => d.code == hovered)[mapKey].toLocaleString()} ${units[mapKey]}</strong>` : ''
								}/>
							</MapLayer>
						<MapLayer
					  	id="lad-line"
					  	type="line"
					  	paint={{
					  		'line-color': ['case',
					  			['==', ['feature-state', 'hovered'], true], 'orange',
					  			['==', ['feature-state', 'selected'], true], 'black',
					  			['==', ['feature-state', 'highlighted'], true], 'black',
					  			'rgba(255,255,255,0)'
					  		],
					  		'line-width': 2
					  	}}
				    />
				  </MapSource>
				</Map>
			</div>
		</figure>
	</div>

	<div slot="foreground">
		<section data-id="map01">
			<div class="col-medium">
				<p>
					This map shows <strong>population density</strong> by district. Districts are coloured from <Em color={colors.seq[0]}>least dense</Em> to <Em color={colors.seq[4]}>most dense</Em>. You can hover to see the district name and density.
				</p>
			</div>
		</section>
		<section data-id="map02">
			<div class="col-medium">
				<p>
					The map now shows <strong>median age</strong>, from <Em color={colors.seq[0]}>youngest</Em> to <Em color={colors.seq[4]}>oldest</Em>.
				</p>
			</div>
		</section>
		<section data-id="map03">
			<div class="col-medium">
				<p>
					The map is now zoomed on <Em color={data.district.indicators.find(d => d.code == selected).age_med_color}>{place.name}</Em>, which has a median age of {data.district.indicators.find(d => d.code == selected).age_med} years.
				</p>
			</div>
		</section>
		<section data-id="map04">
			<div class="col-medium">
				<h3>Select a district</h3>
				<p><label for="map-select">Use the selection box below or click on the map to select and zoom to a district.</label></p>
					<p>
						<Select id="map-select" idKey="code" labelKey="name" items={meta.district.array} value={place} on:select={doSelect} isClearable={false}/>
					</p>
			</div>
		</section>
	</div>
</Scroller>

<Divider/>
{/if}

<Section>
	<h2>{place ? 'Other versions of this article' : 'All versions of this article'}</h2>
	<p><Icon type="arrow" rotation={showList ? 90 : 0}/> <button class="btn-text" on:click={() => showList = !showList}>{showList ? 'Hide' : 'Show'} list of local authorities</button></p>
</Section>

<div class:visually-hidden="{!showList}">
<Media col="wide" grid="narrow">
	{#each [...meta.region.array].sort((a, b) => a.code.localeCompare(b.code)) as region}
	<div class="text-small">
		<strong>{region.name}</strong><br/>
		{#each meta.district.array.filter(d => d.parent == region.code) as place}
		<a href="{base}/{place.code}">{place.name}</a><br/>
		{/each}
	</div>
	{/each}
</Media>
</div>

<Divider/>

<Section>
	<h2>How to use this template</h2>
	<p>
		You can find the source code and documentation on how to use this template in <a href="https://github.com/ONSvisual/svelte-scrolly/" target="_blank">this Github repo</a>.
	</p>
</Section>

<style>
	/* Styles specific to elements within the demo */
	:global(svelte-scroller-foreground) {
		pointer-events: none !important;
	}
	:global(svelte-scroller-foreground section div) {
		pointer-events: all !important;
	}
	button {
		cursor: pointer;
	}
	.chart {
		margin-top: 45px;
		width: calc(100% - 5px);
	}
	.chart-full {
		margin: 0 20px;
	}
	.chart-sml {
		font-size: 0.85em;
	}
	.btn-text {
		border: none;
		background: none;
		margin: 0;
		padding: 0;
		text-decoration: underline;
		color: #206095;
	}
	.btn-text:hover {
		color: black;
	}
</style>

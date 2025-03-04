<script>
  import { onMount } from "svelte"

  export let analyticsId; // Required. Google analytics/tag manager ID
  export let analyticsProps = {}; // Optional props to describe the content
  export let usageCookies = false; // True if usage cookies are allowed (to be read from parent component)
  export let gtag = () => null; // Analytics events will be null unless analytics is enabled
  export let page = null; // Pass Svelte Kit's $page to track navigation in multi-page apps

  let live; // Don't run analytics unless page is live on ONS site (re-set in the onMount function)

  let showBanner = false;
  let showConfirm = false;
  let message = "";
  let location = null; // For keeping track of navigation multi-page apps

  function hasCookiesPreferencesSet() {
    return -1 < document.cookie.indexOf("cookies_preferences_set=true")
  }

  // Check if usage cookies are allowed (for Google Analytics + Hotjar)
  function getUsageCookieValue() {
    var cookiesPolicyCookie = document.cookie.match(new RegExp("(^|;) ?cookies_policy=([^;]*)(;|$)"));
    if (cookiesPolicyCookie) {
      var decodedCookie = decodeURIComponent(cookiesPolicyCookie[2]);
      var cookieValue = JSON.parse(decodedCookie);
      return cookieValue.usage;
    }
    return false;
  }

  function extractDomainFromUrl(e) {
    if (0 <= e.indexOf("localhost") || 0 <= e.indexOf("127.0.0.1")) return "localhost";
    var t = e.match(new RegExp("(.co.uk|.gov.uk)"));
    if (t) {
      return "." + e.replace(t[0], "").split(".").pop() + t;
    } else {
      return e;
    }
  }

  // Set site cookie with 'all' or 'essential' cookies
  function setCookie(option) {
    let oneYearInSeconds = 60 * 60 * 24 * 365;
    let url = window.location.hostname;
    let cookiesDomain = extractDomainFromUrl(url);
    let cookiesPreference = !0;
    let encodedCookiesPolicy = `%7B%22essential%22%3Atrue%2C%22usage%22%3A${option == 'all' ? 'true' : 'false'}%7D`;
    let cookiesPath = "/";
    
    document.cookie = `cookies_preferences_set=${cookiesPreference};max-age=${oneYearInSeconds};domain=${cookiesDomain};path=${cookiesPath};`;
    document.cookie = `cookies_policy=${encodedCookiesPolicy};max-age=${oneYearInSeconds};domain=${cookiesDomain};path=${cookiesPath};`;

    message = option == "all" ? "all" : "only essential";
    if (option == "all") usageCookies = true;
    showConfirm = true;
  }

  // Initialise analytics 'dataLayer' and 'gtag' push function
  function initAnalytics() {
    console.log('initialising analytics');
    window.dataLayer = [{
      "analyticsOptOut": false,
      "gtm.whitelist": ["google","hjtc","lcl"],
      "gtm.blacklist": ["customScripts","sp","adm","awct","k","d","j"],
      ...analyticsProps
    }];
    if (page) location =  $page.url.hostname + $page.url.pathname + $page.url.searchParams;
    gtag = function gtag() {
      window.dataLayer.push(arguments);
    };
    window.gtag = gtag;
  	gtag("js", new Date());
    gtag("config", analyticsId);

  };

  // This code is only relevant for multi-page Svelte Kit apps. It sends an analytics event when the URL changes
  $: if (page && gtag() !== null) {
    let newlocation = $page.url.hostname + $page.url.pathname + $page.url.searchParams;
    if (newlocation !== location) {
      location = newlocation;
      gtag('config', analyticsId, {
        page_path : $page.url.pathname,
        page_location: location
      });
      console.log('logged nav to ' + location);
    }
  }

  onMount(() => {
    // live = true;
    live = window.location.hostname == "www.ons.gov.uk" || window.location.hostname == "cy.ons.gov.uk";
    showBanner = !hasCookiesPreferencesSet();
    usageCookies = getUsageCookieValue();
  });
</script>

<svelte:head>
  {#if live && usageCookies}
  <script async src="https://www.googletagmanager.com/gtag/js?id={analyticsId}" on:load={initAnalytics}></script>
  {/if}
</svelte:head>

{#if showBanner}
<section>
  <form
    id="global-cookie-message"
    class="cookies-banner clearfix"
    aria-label="cookie banner">
    {#if !showConfirm}
    <div class="cookies-banner__wrapper wrapper">
      <div>
        <div class="cookies-banner__message font-size--18">
          <h1 class="cookies-banner__heading font-size--h3">
            Tell us whether you accept cookies
          </h1>
          <p class="cookies-banner__body">
            We would like to
            <a href="/cookies">use cookies to collect information</a>
            about how you use <strong>ons.gov.uk</strong>.
          </p>
          <p class="cookies-banner__body">
            We use this information to make the website work as well as possible
            and improve our services.
          </p>
        </div>
        <div class="cookies-banner__buttons">
          <div class="cookies-banner__button cookies-banner__button--accept">
            <button
              class="btn btn--full-width btn--primary btn--focus margin-right--2 font-weight-700 font-size--17 text-wrap"
              data-gtm-accept-cookies="true" type="submit"
              on:click|preventDefault={() => setCookie('all')}>
              Accept all cookies
            </button>
          </div>
          <div class="cookies-banner__button">
            <a role="button" href="/cookies" class="btn btn--full-width btn--primary btn--focus margin-right--2 font-weight-700 font-size--17 text-wrap">
              Set cookie preferences
            </a>
          </div>
          <!--
          <div class="cookies-banner__button">
            <button
              class="btn btn--full-width btn--secondary btn--focus font-weight-700 font-size--17 text-wrap"
              data-gtm-accept-cookies="true"
              on:click|preventDefault={() => setCookie('essential')}>
              Essential cookies only
              </button>
          </div>
          -->
        </div>
      </div>
    </div>
    {:else}
    <div>
      <div class="cookies-banner__wrapper wrapper">
        <div class="col">
          <div class="cookies-banner__message font-size--18">
            <p class="cookies-banner__confirmation-message">
              You’ve accepted {message} cookies. You can
              <a href="/cookies">change your cookie settings</a>
              at any time.
              <button
                type="button"
                class="cookies-banner__button--hide"
                on:click={() => showBanner = false}>
                Hide
              </button>
            </p>
          </div>
        </div>
      </div>
    </div>
    {/if}
  </form>
</section>
{/if}

<style>
  section {
    background-color:#e5e5e5;
  }
  #global-cookie-message {
    width: 100%;
    max-width:980px;
    margin:0 24px;
  }
  .wrapper{
    box-sizing: border-box;
    width:100%;
  }
  .cookies-banner{
    padding:20px 0;
    box-sizing:border-box;
  }
  @media(max-width:768px){
    .cookies-banner{
        padding:10px 0;
    }
  }
  .cookies-banner__wrapper{
    margin-left:auto;
    margin-right:auto;
  }
  .cookies-banner__heading{
    font-weight:800;
  }
  .cookies-banner__body{
    padding:0;
  }
  .cookies-banner__buttons{
    display:flex;
    display:-ms-flexbox;
    justify-content:left;
    align-items:center;
    margin-top:1rem;
  }
  @media(max-width:768px){
    .cookies-banner__buttons{
        flex-direction:column;
        justify-content:center;
        align-items:center;
    }
  }
  .cookies-banner__button{
    display:inline-block;
    margin-right:8px;
  }
  @media(max-width:768px){
    .cookies-banner__button{
        margin-top:8px;
        margin-right:0;
        width:100%;
        display:block;
    }
  }
  .cookies-banner__button--hide{
    -webkit-font-smoothing:antialiased;
    -moz-osx-font-smoothing:grayscale;
    font-weight:400;
    font-size:18px;
    line-height:1.25;
    outline:0;
    border:0;
    background:0 0;
    text-decoration:underline;
    color:#206095;
    padding:0;
    float:right;
  }
  @media(max-width:768px){
    .cookies-banner__button--hide{
        padding:1rem 0;
        display:block;
        float:none;
    }
  }
  .cookies-banner a{
    text-decoration:none;
  }
  .cookies-banner p,.cookies-banner .markdown li p:nth-of-type(2),.markdown li .cookies-banner p:nth-of-type(2),.cookies-banner .section__content--markdown li p:nth-of-type(2),.section__content--markdown li .cookies-banner p:nth-of-type(2),.cookies-banner .section__content--static-markdown li p:nth-of-type(2),.section__content--static-markdown li .cookies-banner p:nth-of-type(2){
    padding:0;
    margin:8px 0;
  }
  .wrapper,.col,.clearfix{
    *zoom:1;
  }
  .wrapper:before,.col:before,.clearfix:before,.wrapper:after,.col:after,.clearfix:after{
    content:"";
    display:table;
  }
  .wrapper:after,.col:after,.clearfix:after{
    clear:both;
  }
  .font-size--18 {
    font-size:18px;
  }
  .font-size--17{
    font-size:17px!important;
  }
  .font-size--h3{
    font-size: 21px;
    line-height: 24px;
    margin: 16px 0 0;
    padding: 3px 0 5px;
    orphans:3;
    widows:3;
  }
  button{
    cursor:pointer;
  }
  .btn{
    box-sizing: border-box;
    font-family:open sans,Helvetica,Arial,sans-serif;
    font-weight:400;
    font-size:14px;
    display:inline-block;
    width:auto;
    cursor:pointer;
    padding:6px 16px 10px;
    margin:0;
    border:0;
    text-align:center;
    -webkit-appearance:none;
    transition:background-color .25s ease-out;
    text-decoration:none;
    line-height:24px;
  }
  .btn--primary{
    background-color:#0f8243;
    color:#fff;
  }
  .btn--primary:hover,.btn--primary:focus{
    background-color:#0b5d30;
  }
  .btn--secondary{
    background-color:#6d6e72;
    color:#fff;
  }
  .btn--secondary:hover,.btn--secondary:focus{
    background-color:#323132;
  }
  .btn--full-width{
    display:block;
    width:100%;
  }
  .btn--focus:focus{
    -webkit-box-shadow:0 0 0 3px #f93;
    -moz-box-shadow:0 0 0 3px #f93;
    box-shadow:0 0 0 3px #f93;
    outline:0;
  }
	.margin-right--2{
		margin-right:32px!important;
	}
  strong,.font-weight-700{
    font-weight:700!important;
  }
  .text-wrap{
    white-space:normal;
  }
</style>
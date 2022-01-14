#!/bin/bash

sed -i.bak '1s/^import html2canvas.*$//' node_modules/@onsvisual/svelte-charts/src/js/utils.js

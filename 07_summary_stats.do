clear all

// Examples
use "$DATA/analysis_data.dta", clear
keep if brand == "Xyzal" & form == "Tablet" & size == 80 & multipack == 1
bysort website period_id: assert _n == 1
replace price = . if flag_imputed_price == 1

twoway (line price period_id if website == "A", cmissing(n) color(black%65)) ///
	(line price period_id if website == "B", cmissing(n) color(olive_teal*1.1%90)) ///
	(line price period_id if website == "C", cmissing(n) color(navy%80)) ///
	(line price period_id if website == "D", cmissing(n) color(maroon%80)) ///
	(line price period_id if website == "E", cmissing(n) color(orange*1.3%80)), ///
	ylabel(, tposition(inside) angle(horizontal) format(%4.0f))  ///
	xlabel(0(2400)12000, tposition(inside)) /// 
	legend(region(lcolor(white)) order(1 "A" 2 "B" 3 "C" 4 "D" 5 "E") cols(5)) ///  legend(off) 
	ytitle("Price") xtitle("Hours Elapsed in Sample") 
graph export "$FIGURES/xyzal_tablet_80.pdf", replace

/*
* Slides: A and D only
twoway (line price period_id if website == "A", cmissing(n) lcolor("204 51 51")) ///
	(line price period_id if website == "D", cmissing(n) lcolor("51 102 204")), ///
		ytitle("Price") xtitle("Hours Elapsed in Sample") ///
		ylabel(, tposition(inside) angle(horizontal) format(%4.0f))  ///
		xlabel(0(2400)12000, tposition(inside)) /// 
		legend(region(lcolor(white)) order(1 "Retailer A" 2 "Retailer D") cols(5)) 
graph export "$FIGURES/xyzal_tablet_80_AD_v2.pdf", replace
*/

use "$DATA/analysis_data.dta", clear
keep if brand == "Claritin" & form == "Tablet" & size == 70 & multipack == 1
bysort website period_id: assert _n == 1
replace price = . if flag_imputed_price == 1

sort website period_id
twoway (line price period_id if website == "A", cmissing(n) color(black%65)) ///
	(line price period_id if website == "B", cmissing(n) color(olive_teal*1.1%90)) ///
	(line price period_id if website == "C", cmissing(n) color(navy%80)) ///
	(line price period_id if website == "D", cmissing(n) color(maroon%80)) ///
	(line price period_id if website == "E", cmissing(n) color(orange*1.3%80)), ///
	ylabel(, tposition(inside) angle(horizontal) format(%4.0f))  ///
	xlabel(0(2400)12000, tposition(inside)) /// 
	legend(region(lcolor(white)) order(1 "A" 2 "B" 3 "C" 4 "D" 5 "E") cols(5)) ///  legend(off) 
	ytitle("Price") xtitle("Hours Elapsed in Sample") 
graph export "$FIGURES/claritin_tablet_70.pdf", replace

* Daily Statistics
use "$DATA/analysis_data.dta", clear
gen abs_price_change = abs(price - price[_n-1]) if price_change
collapse (sum) n_price_change = price_change abs_price_change observations = is_observed ///
	(max) has_price_change = price_change is_observed (mean) price, ///
	by(website product_website_id date)
collapse (sum) n_price_change abs_price_change has_price_change observations n_products = is_observed ///
	(mean) price (sd) sd_price = price (p10) price_10 = price (p90) price_90 = price, by(website date)

gen price_change_per_product = n_price_change/n_products
gen has_price_change_per_product = has_price_change/n_products
gen price_changes_conditional = n_price_change/has_price_change
gen obs_per_product = observations/n_products
gen avg_abs_price_change = abs_price_change/n_price_change
format obs_per_product n_products %9.1f
format price_change_per_product has_price_change_per_product %9.2f
gen dow = dow(date)

* Count of products, weekly average
preserve
	encode website, gen(website_code)
	tsset website_code date
	gen week = date - dow
	collapse (mean) n_products, by(website week)
	format week %td
	twoway (line n_products week if website == "A", lcolor(black%65)) ///
	(line n_products week if website == "B", lcolor(olive_teal*1.1%90)) ///
	(line n_products week if website == "C", lcolor(navy%80)) ///
	(line n_products week if website == "D", lcolor(maroon%80)) ///
	(line n_products week if website == "E", lcolor(orange*1.3%80)), ///
		ytitle("Count of Products") ylabel(, format(%9.0f)) ///
		xtitle("Date") ///
		legend(label(1 "A") label(2 "B") label(3 "C") label(4 "D") label(5 "E") cols(5)) ///
		xscale(range(21284 21837)) scale(0.95)
	graph export "$FIGURES/count_products_weekly.pdf", replace
restore

* Summary Stats Table
label variable n_products "Count of Products"
label variable obs_per_product "Observations per Product"
label variable price "Price: Mean"
label variable price_10 "Price: 10th Percentile of Products"
label variable price_90 "Price: 90th Percentile of Products"
label variable avg_abs_price_change "Mean Absolute Price Change"
label variable price_change_per_product "Price Changes per Product"
label variable has_price_change_per_product "Share of Products with a Price Change"
	
	
global part1 "n_products obs_per_product"
estpost su $part1 if website == "A"
est store A
estpost su $part1 if website == "B"
est store B
estpost su $part1 if website == "C"
est store C
estpost su $part1 if website == "D"
est store D
estpost su $part1 if website == "E"
est store E
estpost su $part1 
est store F

esttab A B C D E F using "$TABLES/daily_stats.tex", replace ///
		nomtitles ///
		cells(mean(fmt(1))) label booktabs nonum collabels(none) f noobs

global part2 "price price_10 price_90 avg_abs_price_change price_change_per_product"
estpost su $part2 if website == "A"
est store A
estpost su $part2 if website == "B"
est store B
estpost su $part2 if website == "C"
est store C
estpost su $part2 if website == "D"
est store D
estpost su $part2 if website == "E"
est store E
estpost su $part2 
est store F

esttab A B C D E F using "$TABLES/daily_stats.tex", append ///
		nomtitles ///
		cells(mean(fmt(2))) label booktabs nonum collabels(none) f noobs plain

global part3 "has_price_change_per_product"
estpost su $part3 if website == "A"
est store A
estpost su $part3 if website == "B"
est store B
estpost su $part3 if website == "C"
est store C
estpost su $part3 if website == "D"
est store D
estpost su $part3 if website == "E"
est store E
estpost su $part3 
est store F

esttab A B C D E F using "$TABLES/daily_stats.tex", append ///
		nomtitles ///
		cells(mean(fmt(3))) label booktabs nonum collabels(none) f noobs plain

* Brand-website tabulation		
use "$DATA/analysis_data.dta", clear
keep if price != .
estpost tabulate website brand
esttab using "$TABLES/website_brand.tex", cell(b(fmt(%9.0fc))) unstack collabels(none) noobs nonumber nomtitle ///
	eqlabels(, lhs("Retailer")) varlabels(, blist(Total "\hline ")) replace  alignment(r) fragment ///
	title("Price Observations by Website and Brand \label{tab:website-brand}")

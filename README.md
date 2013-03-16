ConceptScroll
=============

Pages Scroller with looping support.<br />
It mimics UIScrollView functionality with paging = YES and additionaly introduces 'looping' mode BOOL property.<br />
<br />
Demo: http://youtu.be/AxZhPDLQpnw<br />
<br />
This is iOS example project that uses PagerView component.<br />
PagerView mimics UIScrollView component with paging mode enabled.<br />
Plus it implements additional 'looping' feature: scrolls to the very first page after the last one.<br />
<br />
PagerView has .delegate and .dataSource properties implemented with UITableView in mind.<br />
<br />
#### TODO:

  1. <b>Vertical sliding</b>. Animate swipping between pages in Vertical direction in addition to Horizontal(current) direction.
  2. <b>Multiple active pages</b>. Implement case when multiple pages are visible and should be rendered together.
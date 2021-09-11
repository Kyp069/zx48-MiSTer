<h3>Alternative ZX Spectrum 48K FPGA implementation for MiSTer</h3>

<p>Implements a standard ZX Spectrum 48K computer and the follwing hardware:</p>
<ul>
<li>DivMMC (works with VHD or secondary SD)</li>
<li>Specdrum</li>
<li>Turbosound</li>
<li>SA1099</li>
<li>Load</li>
</ul>

<p>Keyboard shortcuts</p>
<ul>
<li>F6 - reset
<li>F5 - NMI
</ul>

<p>To avoid flickering in HDMI output change this mister.ini parameter:<br />
vsync_adjust=1</p>
<p>If you only want to change this setting for this core add<br />
[zx48]<br />
vsync_adjust=1</p>
at the end of mister.ini</p>

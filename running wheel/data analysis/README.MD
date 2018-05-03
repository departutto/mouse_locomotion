<i>Last updated on May 3, 2018.</i>
<p>
Scripts:<br>
<ul>
<li>
<b>get_statistics.py</b> - provides statistics on the locomotion signal.<br><br>
<b>Example (in the command line).</b><br> >> python get_statistis.py data_file.txt<br>
Successfully processed: data_file.txt<br>
Total number of the retrieved data points is 437601.<br>
Out of those, 437601 points are proper real numbers.<br>
We used 1.00 cm/sec as the threshold to detect locomotion.<br>
The number of data points above the threshold is 371443 (84.88%).<br>
The number of data points below the threshold is 66158 (15.12%).<br>
The average locomotion speed is 18.32 cm/sec.<br>
The median locomotion speed is 18.00 cm/sec.<br>
The 25th-75th percentiles of the locomotion speed are [ 10.2  26.8] cm/sec.<br>
The standard deviation of the locomotion speed is 9.81 cm/sec.<br>
The maximum locomotion speed detected is 48.70 cm/sec.<br>
</li>
<br>
<li>
<b>split_per_presentation.py</b> - splits the locomotion signal per stimulus presentation.<br><br>
<b>Example (in the command line).</b><br> >> python split_per_presentation.py data_file.txt<br>
Filename = data_file.txt<br>
N(data points) = 437601<br>
N(corrupted) = 0<br><br>
<b>Output.</b>
<ul>
<li>Matlab file data_file.txt.m that contains the locomotion signal per stimulus presentation.</li>
<li>Figure file data_file.txt.jpg that shows duration of stimulus presentations and inter-trial intervals. 
Note that a single trial is assumed to consist of two stimulus presentations.<br><img src="data_file.txt.jpg"></li>
</ul>
</li>
</ul>

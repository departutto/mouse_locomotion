<b>Example of using script 'generate_trials.m'.</b><p>
<ul>
<li>Open Matlab Editor by typing in 'edit' in the Matlab command line.</li>
<li>Open script 'generate_trials.m' in the Matlab Editor.</li>
<li>Make block no. 1 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).</li>
<li>Make block no. 2 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).<br>
<i>Script output: Events file: C:\Users\u0062274\Desktop\recordings\08-may-2018\datafiles\Events.nev</i><br>
<i>Script output: Block no. 2 was complete.</i></li>
<li>Make block no. 3 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).<br>
<i>Script output: Situation #1: Header start and stop indices = 5690 x 5697</i></li>
<li>Remove one record from the data structure 'consolidated' by typing in the following instruction.<br>
<i>>> consolidated = [consolidated(1:5690, :); consolidated(5692:end, :)];</i><br>
<li>Make block no. 3 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).<br>
<i>Script output: Situation #1: Header start and stop indices = 32229 x 32236</i></li>
<li>Remove one record from the data structure 'consolidated' by typing in the following instruction.<br>
<i>>> consolidated = [consolidated(1:32229, :); consolidated(32231:end, :)];</i></li>
<li>Make block no. 3 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).<br>
<i>Script output: N(Header start and stop entries) = 1923 x 1923</i><br>
<i>Block no. 3 was complete.</i></li>
<li>Make block no. 4 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).<br>
<i>Block no. 4 was complete.</i></li>
<li>Make block no. 5 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).<br>
<i>Unique conditions = [1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36]</i><br>
<i>Block no. 5 was complete.</i></li>
<li>Make block no. 6 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).<br>
<i>Block no. 6 was complete.</i></li>
<li>Make block no. 7 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).<br>
<i>Block no. 7 was complete.</i></li>
<li>Save the variables 'consolidated', 'time0', and 'trials' in a file (e.g., >> save '2018-05-08-mouse-68865-run-01.mat').</li>
<li>Clear the Matlab workspace by typing in 'clear all' in the Matlab command line.</li>
</ul>
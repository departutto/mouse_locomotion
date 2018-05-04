 <i>Last modified on May 4, 2018.</i><p>
 
 All Matlab files in the folder should be distributed among the setup computers according to the following scheme:<br><br>
 
 <img src='file_allocation_scheme.jpg'><br><br>
 
 List of the Matlab files:
 
 <ul>
 
 <li><b>Run on the Cheetah PC:</b></li>
   <ul>
     <li><i>plot_online_PSTHs.m</i> - plots on-line PSTHs for channel 'acq_entity' for the maximum of 'n_rows' x 'n_columns' stimulus
     conditions (see script). The actual number of stimulus conditions used in a particular test must not exceed the maximum allowed
     number set in this script.</li>
   </ul>
   
 <li><b>Run on the Control PC:</b></li>
   <ul>
     <li><i>client_csdAnalysis.m</i> - presentation of full-screen flashing checkerboards.</li> 
     <li><i>client_mappingRF.m</i> - presentation of a single white square on the black background at the predetermined positions evenly
     distributed across the screen.</li>
     <li><i>client_searchTest.m</i> - presentation of a random sequence of stimuli at a specified position on the screen; only one 
     stimulus is presented at a time, and any two consecutive stimuli are separated by a blank screen.</li>
     <li><i>client_stimRepetition.m</i> - presentation of stimulus repetitions (e.g., X->X) and stimulus alternations (e.g., Y->X); each
     of the two stimuli is presented at the same position and for the same time, and the two stimuli are separated by a blank screen.</li>
   </ul>
   
 <li><b>Run on the Stimulus PC:</b></li>
   <ul>
     <li><i>server_script.m</i> - must be run first; switches between different tests and communicates the experimenter's parameters
     into those tests.</li>
     <li><i>server_csdAnalysis.m</i> - implementation of stimulus presentation for client_csdAnalysis.m.</li>
     <li><i>server_mappingRF</i> - implementation of stimulus presentation for client_mappingRF.m.</li>
     <li><i>server_searchTest.m</i> - implementation of stimulus presentation for client_searchTest.m.</li>
     <li><i>server_stimRepetition.m</i> - implementation of stimulus presentation for client_stimRepetition.m.</li>
   </ul>
   
 </ul>
 
 <br><br>
 
 Connection scheme between the Cheetah Data Acquisition box and a photodiode attached onto the screen of Stimulus PC:<br><br>
 <img scr='./neuralynx_photocell_connection_scheme.jpg'>

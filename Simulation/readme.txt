Steps to run the simulation using the 2 classes that we built, WirelessSimulator.m & Cluster.m: 

1st: Run Power_Sim.m/Power_Sim_dome.m 

- Create the scenario using the hyperparameter (e.g., Xbound, YBound, NPoints, etc.) and save the Su x Su matrix as a .mat file

2nd: Run Visual_Sim.m 

- To visualize the 3d scatter plot, cdfplot, siteviewer (feature physical space of tx/rx on the map). 

3rd: Run Connectivity_Sim.m

- To visualize threshold connectivity for the nodes within the cluster using different probabilistic models (i.e., Binary, Bernoulli). 

[ OPTIONAL ] 

- We can get a video of the connectivity or the link for the node within the cluster using Connectivity_Video, in addition to the Connectivity_Sim.m 
Also, output another .mat file that we can use to run the threshold using ThresholdSweep_Animation.Sim.m sweep to visualize different power 
sweeping for when nodes in the cluster reach a consensus. 

- The IterationSweep_Animation.m allows us to visualize the link count per iteration based on our probabilistic model. 
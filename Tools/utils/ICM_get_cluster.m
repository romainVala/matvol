function cluster = ICM_get_cluster()
% Simple, you can use it to assert of the cluster profil is ok.
%
% See also ICM_start_cluster

global ICM_CLUSTER

cluster = parcluster('ICM_cluster');
ICM_CLUSTER = cluster;

end % function

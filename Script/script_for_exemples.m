
% exemples


dir ='/network/lustre/iss01/cenir/analyse/irm/users/salim.ouarab';
data = gdir(dir, 'COVID$');
suj = gdir(data,'^2');

dtiin = get_subdir_regex_multi(suj,'^S.._Ax_DTI_.*1000')
%dtiout = r_mkdir(suj{2},'dti')
dtiout = gdir(suj,'dti$');

% use only eddycor
clear par; par.jobname='dtieddy2';
par.do_denoise = 1;
par.remove_gibs = 1; 
par.sge=1;
par.use_topup = 0;
par.acqp = '-1 0 0 0.17';  % Col R/L et j- = -1  TotalReadoutTime ~ 0.17, 


dti_import_multiple({dtiin{2}},{dtiout{2}},par)  % test for suj 2

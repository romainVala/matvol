function out = do_mr_scale(fin,scale,fo,par)
%function out = do_mr_scale(fin,scale,fo,par)
%

if ~exist('par'),par ='';end

defpar.sge=0;
defpar.jobname='mr_calc_scale';


par = complet_struct(par,defpar);


for k=1:length(fin)
    cmd{k} =  sprintf('mrcalc %s %f -multiply -force %s',fin{k},scale(k),fo{k});
end
out=fo;

do_cmd_sge(cmd,par);

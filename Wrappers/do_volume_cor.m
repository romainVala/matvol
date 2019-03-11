function  do_volume_cor(fin,outdir,par)

if ~exist('par'),par ='';end

defpar.type = 'stretch_scalar_product'; % raw_scalar_product

defpar.sge=0;
defpar.jobname = 'volcor';
defpar.skip = 1;
defpar.select='';
defpar.update=0;

par = complet_struct(par,defpar);

if ~exist(outdir,'dir')
    mkdir(outdir)
end


    cmd = sprintf('%s\nFREF=%s',cmd,fin{k});

switch par.type
    case 'stretch_scalar_product'
        
        cmdc3 = sprintf('c3d -percent-intensity-mode ForegroundQuantile $FREF -clip 0 inf  -stretch 0%%%% 98%%%% 0 200 -clip 0 255 \\\\' );
        cmdc3 = sprintf('%s\n      $i  -clip 0 inf  -stretch 0%%%% 98%%%% 0 200 -clip 0 255 \\\\',cmdc3);
            
        cmdc3 = sprintf('%s\n       -multiply -voxel-sum |awk ''{print $3}'' ',cmdc3);
    

    case 'raw_scalar_product'
        cmdc3 = sprintf('c3d  $FREF $i  -multiply -voxel-sum |awk ''{print $3}'' ');
    case 'raw_ncorr'
        cmdc3 = sprintf('c3d  $FREF $i -ncor |awk ''{print $3}'' ');
    case 'raw_mi'
        cmdc3 = sprintf('c3d  $FREF $i -nmi |awk ''{print $3}'' ');
    case 'cor_hist'
        cmdc3 = sprintf('read_hist.py $FREF $i');
    case 'reg_ln'
        cmdc3 = sprintf('reg_measure -ref $FREF -flo $i -ncc -lncc -nmi | awk ''{print $2}'' |tr  ''\\\\n'' '','' |  sed ''s/$/\\\\n/'' ');
end

job={};


do_cmd_sge(job,par);






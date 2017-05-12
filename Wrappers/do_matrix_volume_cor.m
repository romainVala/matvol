function  do_matrix_volume_cor(fin,outdir,par)

if ~exist('par'),par ='';end

defpar.type = 'stretch_scalar_product'; % raw_scalar_product

defpar.sge=0;
defpar.jobname = 'dmatcor';
defpar.walltime = '46:00:00';
defpar.sge_queu='long';
defpar.job_pack = 5;
defpar.skip = 1;
defpar.select='';
defpar.random=0;
defpar.linename = 'line';
defpar.update=0;

par = complet_struct(par,defpar);

if ~exist(outdir,'dir')
    mkdir(outdir)
end

fname_file = fullfile(outdir,'matrix_files.txt');
if exist(fname_file,'file') && (par.skip | par.update(1))
    fprintf('TAKING existing file %s\n',fname_file);
    %check
    l=readtext(fullfile(outdir,'matrix_files.txt'));
    fin=l;
%    keyboard
%    if ~any(strcmp(fin,l'))        error ('mismatch between fin and matrix_files.txt');end
        
else
    ffid=fopen(fname_file,'w');
    fprintf(ffid,'%s\n',fin{:})
    fclose(ffid);
end

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
if par.update
    indice_todo=par.update;else
    indice_todo=1:length(fin);end

for k=indice_todo
    fileout = fullfile(outdir,sprintf('%s_j%.5d',par.linename,k));
    if par.skip && exist(fileout,'file') && ~par.update(1)
        continue
    end
    cmd = sprintf('\n cd %s',outdir);
    %cmd = sprintf('%s\nFREF=`cat matrix_files.txt |head -%d|tail -1` ',cmd,k);
    cmd = sprintf('%s\nFREF=%s',cmd,fin{k});

    cmd = sprintf('%s\ntouch %s',cmd,fileout);
    
    %if par.update
        cmd = sprintf('%s\n\n nbi=`cat line_j%.5d|wc -l`  \n nbtodo=$((%d-nbi))',cmd,k,k);
        cmd = sprintf('%s\nfor i in `cat matrix_files.txt | head -%d | tail -$nbtodo` ;',cmd,k);
    %else
    %    cmd = sprintf('%s\nfor i in `cat matrix_files.txt | head -%d` ;',cmd,k);
    %end
    
    cmd = sprintf('%s\ndo',cmd);
    %cmd = sprintf('%s\n  ',cmd);
    %I add -clip 0 inf car rmniMas has negative value in the border due to mrtransform -template
    
    cmd = sprintf('%s\n %s  >> %s_j%.5d; ',cmd,cmdc3,par.linename,k);

    cmd = sprintf('%s\n done',cmd);
    job{end+1} = cmd;
end


if ~isempty(par.select)
    job = job(par.select)
end

if par.random
    job = job(randperm(length(job)));
end

do_cmd_sge(job,par);

















if 0 %too long with 10k
    for k=1:length(fin)
        [d fref] = get_parent_path(fin(k));
        
        cmd{k} =  sprintf('\n cd %s',d{1});
        cmd{k} =  sprintf('%s\n rm -f scalar_product*  ',cmd{k});
        cmd{k} = sprintf('%s\n maxref=`fslstats %s -P 98`',cmd{k},fref{1});
        
        for kk=1:length(fin)
            cmd{k} = sprintf('%s\n echo %s >> scalar_product_files',cmd{k},fin{kk});
            cmd{k} = sprintf('%s\n max2=`fslstats %s -P 98` ',cmd{k},fin{kk});
            cmd{k} = sprintf('%s\n c3d %s -stretch 0 $maxref 0 200 -clip 0 255 %s  -stretch 0 $max2 0 200 -clip 0 255 -multiply -voxel-sum |awk ''{print $3}'' >> scalar_product\n',cmd{k},fref{1},fin{kk});
        end
        
    end
    
    %boucle avec fslstats
    for k=1:length(fin)
        cmd = sprintf('\n cd %s',outdir);
        %cmd = sprintf('%s\nFREF=`cat matrix_files.txt |head -%d|tail -1` ',cmd,k);
        cmd = sprintf('%s\nFREF=%s',cmd,fin{k});
        cmd = sprintf('%s\nCNUM=%d',cmd,k);
        
        cmd = sprintf('%s\nmaxref=`fslstats $FREF -P 98`;',cmd);
        cmd = sprintf('%s\n',cmd);
        cmd = sprintf('%s\nfor i in `cat matrix_files.txt` ;',cmd);
        cmd = sprintf('%s\ndo',cmd);
        cmd = sprintf('%s\nmax2=`fslstats $i -P 98`',cmd);
        %cmd = sprintf('%s\n  ',cmd);
        cmd = sprintf('%s\nc3d $FREF -stretch 0 $maxref 0 200 -clip 0 255 \\\\' ,cmd);
        cmd = sprintf('%s\n      $i  -stretch 0 $max2 0 200 -clip 0 255 \\\\',cmd);
        cmd = sprintf('%s\n       -multiply -voxel-sum |awk ''{print $3}'' >> %s_j%.5d; ',cmd,par.linename,k);
        cmd = sprintf('%s\n done',cmd);
        job{k} = cmd;
    end
    
end



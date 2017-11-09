function fo = do_fsl_slicer(f,outdir,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('outdir','var')
    outdir = pwd;
end

if ~exist('par'),par ='';end

defpar.suffix='';
defpar.prefix='';
defpar.sge=0;
defpar.jobname = 'fslslicer';
defpar.walltime = '00:10:00';
defpar.sge_queu='express';
defpar.type = '3x3'; % '3x5' '3x3'  '3x4 overlay' 3x1 montage256
par = complet_struct(par,defpar);

[a b] = unix('which fslmaths');
fslbindir = get_parent_path(b);

f=cellstr(char(f));

diro =get_parent_path(f);
[pp fo ]=get_parent_path(diro,-4);

if ~isempty(par.suffix)
    fo=addsuffixtofilenames(fo,par.suffix);
end
if ~isempty(par.prefix)
    fo=addprefixtofilenames(fo,par.prefix);
end

if ~exist(outdir,'dir')
    mkdir(outdir)
end

if strcmp(par.type,'montage256')
    do_montage=256;
    par.type='3x1';
else
    do_montage=0;
end


for k=1:length(f)
    tmpdir = tempname;
            
    switch par.type
        case '2x2m' 
            fref = get_subdir_regex_files(diro(k),'^ms',1);
            fmask = get_subdir_regex_files(diro(k),'^mask_p',1);
            
            cmd = sprintf('mkdir %s\n cd %s\n ',tmpdir,tmpdir);
            cmd = sprintf('%s maxi=`fslstats %s -k %s -P 98`\n',cmd,fref{1},fmask{1});
            cmd = sprintf('%s c3d %s  -stretch 0 $maxi 0 255 -clip 0 255  -as OO ',cmd,f{k});
            cmd = sprintf('%s -push OO -slice x 43%%%% -flip xy -type uchar -oo x1.png ',cmd);
            cmd = sprintf('%s -push OO -slice y 45%%%% -flip xy -type uchar -oo y1.png ',cmd);
            cmd = sprintf('%s -push OO -slice z 45%%%% -flip xy -type uchar -oo z1.png ',cmd);
            cmd = sprintf('%s -push OO -slice z 50%%%% -flip xy -type uchar -oo z2.png ',cmd);
            
            cmd = sprintf('%s\n montage y1.png x1.png z* -tile 2x2 -mode Concatenate -background black  %s/%s.jpg',cmd,outdir,fo{k});

        case '2x2' 
 %           fp = get_subdir_regex_files(diro(k),'^rmniMas');            
            
 %           cmd = sprintf('mkdir %s\n cd %s\n c3d %s %s -multiply  -stretch 2%%%% 98%%%% 0 255 -clip 0 255  -as OO ',tmpdir,tmpdir,f{k},fp{1});
            cmd = sprintf('mkdir %s\n cd %s\n c3d %s  -stretch 2%%%% 98%%%% 0 255 -clip 0 255  -as OO ',tmpdir,tmpdir,f{k});
            cmd = sprintf('%s -push OO -slice x 43%%%% -flip xy -type uchar -oo x1.png ',cmd);
            cmd = sprintf('%s -push OO -slice y 45%%%% -flip xy -type uchar -oo y1.png ',cmd);
            cmd = sprintf('%s -push OO -slice z 45%%%% -flip xy -type uchar -oo z1.png ',cmd);
            cmd = sprintf('%s -push OO -slice z 50%%%% -flip xy -type uchar -oo z2.png ',cmd);
            
            cmd = sprintf('%s\n montage y1.png x1.png z* -tile 2x2 -mode Concatenate -background black  %s/%s.jpg',cmd,outdir,fo{k});
             
        case '3x4 overlay'
            cmd = sprintf('mkdir %s\n cd %s\n %s/slicer %s -x 0.35  x1.png -x 0.5  x2.png -x 0.65  x3.png',tmpdir,tmpdir,fslbindir,f{k});
            %cmd = sprintf('%s -z 0.35  z1.png -z 0.5  z2.png -z 0.65  z3.png ',cmd);
            
            fp = get_subdir_regex_files(diro(k),'^bin');fp=cellstr(char(fp));
            if length(fp)==3
                fmask =  get_subdir_regex_files(diro(k),'^mask_prob.nii.gz');
                
                cmd = sprintf('%s\n c3d %s %s -multiply -trim 5vox -stretch 2%%%% 98%%%% 0 255 -clip 0 255  -as OO ',cmd,f{k},fmask{1});
                cmd = sprintf('%s -push OO -slice y 35%%%% -flip xy -type uchar -oo y1.png ',cmd);
                cmd = sprintf('%s -push OO -slice y 50%%%% -flip xy -type uchar -oo y2.png ',cmd);
                cmd = sprintf('%s -push OO -slice z 35%%%% -flip xy -type uchar -oo z1.png ',cmd);
                cmd = sprintf('%s -push OO -slice z 50%%%% -flip xy -type uchar -oo z2.png ',cmd);
                cmd = sprintf('%s -push OO -slice z 58%%%% -flip xy -type uchar -oo z3.png ',cmd);
                cmd = sprintf('%s -push OO -slice z 66%%%% -flip xy -type uchar -oo z4.png ',cmd);
                
                %        cmd = sprintf('%s -z 0.35  z1.png -z 0.65  z3.png ',cmd);
                
                cmd = sprintf('%s\n c3d %s -scale 3 %s -scale 2 -add %s -add -trim 5vox -as S %s ',cmd,fp{1},fp{3},fp{2},f{k});
                cmd = sprintf('%s -stretch 2%%%% 98%%%% 0 255 -clip 0 255 -reslice-identity -push S -foreach -slice z 35%%%% -flip xy -endfor -oli $HOME/bin/c3d_label.txt 0.2  -type uchar  -omc  z1o.png',cmd);
                
                cmd = sprintf('%s\n c3d %s -scale 3 %s -scale 2 -add %s -add -trim 5vox -as S %s ',cmd,fp{1},fp{3},fp{2},f{k});
                cmd = sprintf('%s -stretch 2%%%% 98%%%% 0 255 -clip 0 255 -reslice-identity -push S -foreach -slice z 50%%%% -flip xy -endfor -oli $HOME/bin/c3d_label.txt 0.2  -type uchar  -omc  z2o.png',cmd);
                
                cmd = sprintf('%s\n c3d %s -scale 3 %s -scale 2 -add %s -add -trim 5vox -as S %s ',cmd,fp{1},fp{3},fp{2},f{k});
                cmd = sprintf('%s -stretch 2%%%% 98%%%% 0 255 -clip 0 255 -reslice-identity -push S -foreach -slice z 58%%%% -flip xy -endfor -oli $HOME/bin/c3d_label.txt 0.2  -type uchar  -omc  z3o.png',cmd);
                
                cmd = sprintf('%s\n c3d %s -scale 3 %s -scale 2 -add %s -add -trim 5vox -as S %s ',cmd,fp{1},fp{3},fp{2},f{k});
                cmd = sprintf('%s -stretch 2%%%% 98%%%% 0 255 -clip 0 255 -reslice-identity -push S -foreach -slice z 66%%%% -flip xy -endfor -oli $HOME/bin/c3d_label.txt 0.2  -type uchar  -omc  z4o.png',cmd);
                
                %cmd = sprintf('%s\n convert  \\\\( x1.png   x2.png   x3.png +append \\\\) \\\\( y1.png   z1.png z1o.png  z2.png   z2o.png +append \\\\) \\\\( y2.png  z3.png z3o.png z4.png z4o.png +append \\\\) -append %s/%s.jpg',cmd,outdir,fo{k}) ;
                cmd = sprintf('%s\n convert  \\\\( x1.png   x2.png   x3.png +append \\\\) \\\\( y1.png   z1.png  z2.png z3.png z4.png +append \\\\) \\\\( y2.png z1o.png  z2o.png z3o.png z4o.png  +append \\\\) -append %s/%s.jpg',cmd,outdir,fo{k}) ;
                
            end
        case '3x3'
            
            cmd = sprintf('mkdir %s\n cd %s\n %s/slicer %s -x 0.35  x1.png -x 0.52  x2.png -x 0.65  x3.png',tmpdir,tmpdir,fslbindir,f{k});
            
            cmd = sprintf('%s -y 0.35  y1.png -y 0.52  y2.png -y 0.65  y3.png ',cmd);
            cmd = sprintf('%s -z 0.35  z1.png -z 0.52  z2.png -z 0.65  z3.png ',cmd);
            %cmd = sprintf('%s\n convert  \\\\( x1.png   x2.png   x3.png +append \\\\) \\\\( y1.png  y2.png  y3.png +append \\\\) \\\\( z1.png   z2.png  z3.png +append \\\\) -append %s/%s.jpg',cmd,outdir,fo{k}) ;
            cmd = sprintf('%s\n montage x* y* z*  -geometry 200x200\\\\!+0+0  %s/%s.jpg',cmd,outdir,fo{k});
            %cmd = sprintf('%s\n',cmd);

        case '3x1'
            
            cmd = sprintf('mkdir %s\n cd %s\n %s/slicer %s -x 0.52  x1.png -y 0.52  x2.png -z 0.52  x3.png',tmpdir,tmpdir,fslbindir,f{k});
            
            %cmd = sprintf('%s\n montage x* -geometry 200x200^+0+0  %s/%s.jpg',cmd,outdir,fo{k});
            cmd = sprintf('%s\n convert x* +append  %s/%s.jpg',cmd,outdir,fo{k});
            %cmd = sprintf('%s\n',cmd);

        case '3x5'
            
            cmd = sprintf('mkdir %s\n cd %s\n %s/slicer %s',tmpdir,tmpdir,fslbindir,f{k});

            cmd = sprintf('%s -x 0.35  x1.png -x 0.44  x2.png -x 0.52  x3.png -x 0.60  x4.png -x 0.65  x5.png',cmd);            
            cmd = sprintf('%s -y 0.35  y1.png -y 0.44  y2.png -y 0.52  y3.png -y 0.60  y4.png -y 0.65  y5.png',cmd);
            cmd = sprintf('%s -z 0.35  z1.png -z 0.44  z2.png -z 0.52  z3.png -z 0.60  z4.png -z 0.65  z5.png',cmd);
            %cmd = sprintf('%s\n convert  \\\\( x1.png   x2.png   x3.png +append \\\\) \\\\( y1.png  y2.png  y3.png +append \\\\) \\\\( z1.png   z2.png  z3.png +append \\\\) -append %s/%s.jpg',cmd,outdir,fo{k}) ;
            %cmd = sprintf('%s\n montage x* y* z*  -geometry 200x200\\\\!+0+0  %s/%s.jpg',cmd,outdir,fo{k});
            cmd = sprintf('%s\n montage x* y* z*  -geometry 200x200^+0+0  %s/%s.jpg',cmd,outdir,fo{k});
            %cmd = sprintf('%s\n',cmd);
            
    end
    
    %cmd = sprintf('%s\n %s/pngappend  x1.png +  x2.png +  x3.png -  y1.png +  y2.png +  y3.png -  z1.png +  z2.png +  z3.png %s/%s.png',cmd,fslbindir,outdir,fo{k}) ;
    cmd = sprintf('%s\n cd \n rm -rf %s\n',cmd,tmpdir);
    
    job{k} = cmd;
end

%c3d bin_csf.nii.gz -scale 3 bin_white.nii.gz -scale 2 -add bin_gray.nii.gz -add -trim 5vox -as S ms_S06_t1mpr_SAG_NSel_S176.nii.gz -stretch 2% 98% 0 255 -clip 0 255 -reslice-identity -push S -foreach -slice z 50% -flip xy -endfor -oli ~/bin/c3d_label.txt 0.2  -type uchar  -omc  rgb.png

if do_montage
    [job f_do_qsubar] = do_cmd_sge(job,par);
    [vv ii] = sort(fo);
    
    nbm = 1;
    
    for k=1:256:length(fo)
        cmd = sprintf('cd %s \nmontage ',outdir);
        
        if (k+255) <length(fo)
            jend=k+255;
        else
            jend = length(fo);
        end
        
        for j = k:jend
            cmd = sprintf('%s %s.jpg ',cmd,vv{j});
        end
        
        cmd = sprintf('%s -resize 700x256^ -gravity center -extent 700x256 -geometry 700x256,0,0 -tile 8x32 montage%.3d.png \n',cmd,nbm);        
        job2{nbm} = cmd;
        nbm=nbm+1;
    end
    par.jobname='montage';
    par.job_pack=0;
    
    do_cmd_sge(job2,par,'',f_do_qsubar);
    
else
    
    do_cmd_sge(job,par);

end
 
%option de montage 
% montage a0* -resize 700x256^ -gravity center -extent 700x256 -geometry 700x256,0,0 -tile 8x32 mmm2.jpg
% montage a0* -resize 700x256^ -gravity center -extent 700x256 -mode Concatenate -tile 8x32 mmm2.jpg

% convert pointinterinv.jpg -resize 5600x8192! pointinterinvbig.jpg
% composite -blend 20 pointinterinvbig.jpg  mmm2.jpg  tinv.jpg 





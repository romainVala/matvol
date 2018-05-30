function fo = write_multiple_mask(fi,label,outname,outdir,methode_type,output_vol)

if ~exist('methode_type')
    %  methode_type='marsbar';%'image_calc';
    methode_type='3dcalc';
end

if ~exist('output_vol')
    output_vol='';
else
    if length(fi) ~= length(output_vol)
        error('length of reference to reslice volume should be the same as the input volume')
    end
end


if ~iscell(fi)
    fi = cellstr(fi)';
end
if ~iscell(outdir)
    outdir = cellstr(outdir)';
end

if length(fi) ~= length(outdir)
    error('length outdir should be the same as the input volume')
end


for num_in = 1:length(fi)
    %vi = spm_vol(fi{num_in});
    
    for k=1:length(label)
        
        fo{k} = fullfile(outdir{num_in},[outname{k},'.nii.gz']);
        
        ll = label{k};
        
        if ~exist(fo{k})
            
            switch methode_type
                case '3dcalc'
                    cmd = sprintf('3dcalc -a %s -datum byte -expr',fi{num_in});
                    
                    if size(ll,1)==2 % min and max born
                        cmd = sprintf('%s ''within(a,%f,%f)'' ',cmd,ll(1,1),ll(2,1));
                    elseif size(ll,1)==1
                        cmd = sprintf('%s ''or(equals(a,%f) ',cmd,ll(1));
                        for kk=2:length(ll)
                            cmd = sprintf('%s ,equals(a,%f) ',cmd,ll(kk));
                        end
                        cmd = sprintf('%s )''',cmd);
                    end
                    
                    cmd = sprintf('%s -prefix %s',cmd,fo{k})
                    
                    unix(cmd);
                    
                case 'image_calc'
                    exp = sprintf('i1==%d',ll(1));
                    
                    for kk=2:length(ll)
                        exp = sprintf('%s | i1==%d',exp,ll(kk));
                    end
                    
                    job = job_image_calc(fi(num_in),fo{k},exp,0,2);
                    
                    fprintf('computing mask %s for label %d',fo{k},ll(1));
                    for kk=2:length(ll)
                        fprintf(' and %d',ll(kk));
                    end
                    fprintf('\n');
                    spm_jobman('run',job);
                    %spm_jobman('interactive',job);
                    
                case 'marsbar'
                    
                    fo{k} = fullfile(outdir{num_in},[outname{k},'_roi.mat']);
                    foi{k} = fullfile(outdir{num_in},[outname{k},'.nii']);
                    
                    exp = sprintf('img==%d',ll(1));
                    
                    for kk=2:length(ll)
                        exp = sprintf('%s | img==%d',exp,ll(kk));
                    end
                     vi = spm_vol(fi{num_in});
 
                    roi = maroi_image(struct('vol', vi, 'binarize',1,...
                        'func', exp));
                    roi = maroi_matrix(roi);
                    
                    saveroi(roi,fo{k});
                    
                    if ~isempty(output_vol)
                        vo = spm_vol(output_vol{num_in});
                        sp = mars_space ( struct('dim',vo.dim,'mat', vo.mat) );
                        
                        ppp = voxpts(roi,sp);
                        
                        roio = maroi_pointlist( struct('XYZ',ppp,'mat',vo.mat) , 'vox' );
                        %	roi = maroi_matrix(roio);
                        
                    end
                    
                    do_write_image(roi,foi{k});
                    
                    keyboard
            end
            
        end
        
    end
    
    
    if ~isempty(output_vol)
        
        job = job_reslice(output_vol(num_in),{char(fo)},1,'r_');
        %spm_jobman('interactive',job);
        spm_jobman('run',job);
        
        for kk=1:length(fo)
            delete(fo{kk})
        end
        
    end
    
end



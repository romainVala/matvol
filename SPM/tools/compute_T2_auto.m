function compute_T2_auto(P,TE,par)


if ~exist('par'),par ='';end

defpar.seuilT2=200;
defpar.method = 'lin';%'lin'
defpar.sge=0;
defpar.jobname='computeT2';
defpar.walltime = '10:00:00';
defpar.mask  = '';
defpar.prefix = 'T2MAP_';
defpar.skip = 0;
par = complet_struct(par,defpar);


if ~exist('P')
    Pd = spm_select([1 Inf],'dir','a dir of images','',pwd);
    ff = dir(fullfile(Pd,'*.img'))
    for k=1:length(ff)
        P(k,:) = fullfile(Pd,ff(k).name);
    end
    
end
if ischar(P),    P=cellstr(P);end
%P=cellstr(char(P))
Pd = get_parent_path(P);
Pd = Pd{1}(1,:);

if ~exist('TE') || isempty(TE)
    if exist (fullfile(Pd,'dicom_headers.mat'))
        load(fullfile(Pd,'dicom_headers.mat'))
        
        for k=1:length(dcm)
            Inum(k) = dcm{k}{1}.InstanceNumber;
            TE(k) =  dcm{k}{1}.EchoTime;
        end
        
        [v,i]=sort(Inum);
        TE = TE(i)
    else
        ff=get_subdir_regex_files(Pd,'^dic.*json');
        
        fjson=cellstr(char(ff));
        lj=loadjson(fjson);
        for k=1:length(lj)
            TE(k) = lj(k).global.const.EchoTime;
        end
        
        %         error('can not guess TE (no dicom_header files)')
    end
    
end



if par.sge
    for nbv =1:length(P)
        pp=par;
        pp.sge=0;
        if iscell(par.mask), pp.mask = par.mask(nbv);end
        fin = P(nbv);
        
        var_file = do_cmd_matlab_sge({'compute_T2_auto(fin,TE,pp)'},par);
        save(var_file{1},'fin','TE','pp');
    end
else
    
    for nbv =1:length(P)
        ffp = cellstr(P{nbv});

        T2filename = addprefixtofilenames(ffp{1},par.prefix);
        T2filename = change_file_extension(T2filename,'.nii')
        T2MSEfilename = addprefixtofilenames(T2filename,'MSE');
        
        [VY Alldata] = nifti_spm_vol(ffp);
        if par.skip
            VY(par.skip) = []
        end
        
        NbFiles = length(VY);
        dim = VY(1).dim(1:3);
        
        if iscell(par.mask)
            mask = spm_read_vols(spm_vol(par.mask{nbv}));
        else
            mask=ones(dim);
        end
        x=TE;
        
        
        T2img=VY(1);        T2img.fname =T2filename; %{nbv}(1,:);
        T2img = spm_create_vol(T2img);
        T2MSEimg=VY(1);        T2MSEimg.fname =T2MSEfilename;%{nbv}(1,:);
        T2MSEimg = spm_create_vol(T2MSEimg);
        
        errors=0;
        
        for nb_slice = 1:dim(3)
            
            X2 = zeros(dim(1:2));
            Xmse = zeros(dim(1:2));
            Mi      = spm_matrix([0 0 nb_slice]);
            clear Xm;
            
            for nb_vol = 1:NbFiles
                
                %X       = spm_slice_vol(VY(nb_vol),Mi,VY(nb_vol).dim(1:2),0);
                X = Alldata(:,:,nb_slice,nb_vol);
                Xm(:,nb_vol) = X( (mask(:,:,nb_slice)>0) );
            end
            
            y=log(Xm);
            
            %figure; plot(x,y)
            
            var_x = repmat ( sum((x-mean(x)).^2)/size(y,2), size(y,1),1);
            cv=sum( repmat(x-mean(x),size(y,1),1) .* (y-repmat(mean(y,2),1,size(y,2)) ),2 )/size(y,2);
            
            a=cv./var_x;
            
            at2 = -1./real(a); %when computing with noise background the vector becom complex
            at2(at2<0) = 0;
            at2(at2>par.seuilT2) = 0;
            
            b=mean(y,2)-a*mean(x);
            
            X2(mask(:,:,nb_slice)>0) = at2;
            Xmse(mask(:,:,nb_slice)>0) = at2;
            amse = at2;
            
            switch par.method
                case 'exp'
                    %opts=optimset('Display','off','Robust','on');
                    %opts=statset('Robust','on','Display','off');
                    opts=statset('Display','off');
                    warning('OFF','MATLAB:singularMatrix')
                    warning('OFF','MATLAB:log:logOfZero')
                    warning('OFF','MATLAB:divideByZero')
                    warning('OFF','MATLAB:singularMatrix')
                    
                    %ii=find(X2>0);
                    ii=find(at2>0);
                    
                    for nbp=1:length(ii)
                        yy = Xm(ii(nbp),:);
                        %c'est trop underestimate beta0 = [exp(b(ii(nbp))) at2(ii(nbp))];
                        beta0 = [max(yy) at2(ii(nbp))];
                        %[ betaEnd,R,J,COVB,MSE] = nlinfit(TE,yy,@single_exp,beta0);
                        %a sauver MSE
                        try
                            [ betaEnd ,R,J,COVB,MSE] = nlinfit(TE,yy,@single_exp,beta0,opts);
                            
                        catch
                            errors=errors+1;
                            betaEnd(2)=0;
                            MSE=-1;
                        end
                        %                         X2(ii(nbp)) = betaEnd(2);
                        %                         Xmse(ii(nbp)) = MSE;
                        at2(ii(nbp)) = betaEnd(2);
                        amse(ii(nbp)) = MSE;
                    end
                    
                    X2(mask(:,:,nb_slice)>0) = at2;
                    Xmse(mask(:,:,nb_slice)>0) = amse;
                    
                    spm_write_plane(T2img,X2,nb_slice);
                    spm_write_plane(T2MSEimg,Xmse,nb_slice);
                    
                    
                    
                case 'lin'
                    spm_write_plane(T2img,X2,nb_slice);
            end
            
            
            %   b=mean(y,2) - repmat(mean(x),size(y,1),1).*a;
            %   yest=a*x + repmat(b,1,size(y,2))
            
        end
        
        if errors
            fprintf('Fitting of done with %d errors (%s)\n',errors,T2filename{nbv}(1,:))
        end
        
    end
end
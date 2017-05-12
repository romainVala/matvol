function  [Afull fall ind_to_remove ftodelet jmising] = get_matrix_volume_cor(outdir,par)
%function  [Afull ftodelet jmising] = get_matrix_volume_cor(outdir,par)

if ~exist('par'),par ='';end

defpar.type = 'stretch_scalar_product'; % raw_scalar_product

defpar.sge=0;
defpar.linename = 'line';
defpar.matrix_file = 'matrix_files.txt';
defpar.filematsave = 'cormat';

par = complet_struct(par,defpar);


if iscell(outdir)
    for nbout = 1:length(outdir)
        [Afull{nbout} ftodelet{nbout} jmising{nbout}] = get_matrix_volume_cor(outdir{nbout},par);
    end
    return
end



ftodelet={};jmising={};

filemat_fname = fullfile(outdir,par.filematsave);
if exist(filemat_fname,'file')
    load(filemat_fname)
    Asca = full(asparse);
    Afull = Asca+Asca'-diag(diag(Asca));
    return
end


fname_file = fullfile(outdir,par.matrix_file);
if ~ exist(fname_file,'file') 
    fprintf('Noo file  %s so return\n did you run it ? \n',fname_file);
    return
end

fall=textread(fname_file,'%s');

fprintf('Reading %d lines\n',length(fall))
ind_to_remove=[];

%Asca = zeros(length(fall));

for k=1:length(fall)
    
    fn = fullfile(outdir,sprintf('%s_j%.5d',par.linename,k));
    
    if exist(fn,'file')
        %d=dir(fn);%if datenum(d.date)<dref   
        try
            l = load(fn);
        catch
            fprintf('Corupted line %s \n',fn)
            ftodelet{end+1} = fn;
            ind_to_remove(end+1)=k;

        end
        
        if size(l,1)~=k,           
            ftodelet{end+1} = fn;      
            ind_to_remove(end+1)=k;
        else    
            if ~exist('Asca')
                nbval = size(l,2);
                Asca = zeros(length(fall),length(fall),nbval);
                Asca = squeeze(Asca);
            end
            if nbval>1, Asca([1:k],k,:) = l;
            else,  Asca([1:k],k) = l;
            end
        end
    else
        jmising{end+1}=fn;
        ind_to_remove(end+1)=k;
    end
end


if isempty(ftodelet) & isempty(jmising)
    fprintf('Done\n saving to %s \n',filemat_fname)
    if nbval==3
        %keyboard
        aspar_ncc = sparse(squeeze(Asca(:,:,1)));
        aspar_lnc = sparse(squeeze(Asca(:,:,2)));
        aspar_nmi = sparse(squeeze(Asca(:,:,3)));
        save(filemat_fname,'aspar_ncc','aspar_lnc','aspar_nmi');
    else
        asparse = sparse(Asca);
        save(filemat_fname,'asparse');
    end
    
else
    fprintf('Missing some lines \n %d to be delete and %d missing',length(ftodelet),length(jmising));
end

for nbval=1:size(Asca,3)
    Afull(:,:,nbval) = Asca(:,:,nbval)+Asca(:,:,nbval)'-diag(diag(Asca(:,:,nbval)));
end


%indices of ftodelete
% for k=1:length(ftodelet) 
%      ind(k) = str2num(ftodelet{k}(25:end));
% end






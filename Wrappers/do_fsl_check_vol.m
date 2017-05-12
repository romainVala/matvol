function [vol varargout] = do_fsl_getvol(f,par)
%function [vol varargout] = do_fsl_getvol(f,par)
%output <voxels> <volume> mean std Entropy 98 percentil (for nonzero voxels) or for
%voxel above the threshold seuil
if ~exist('par','var'),  par=''; end

f=cellstr(char(f));

defpar.lthr='';
defpar.uthr='';
defpar.abs=0;
defpar.mask='';
par = complet_struct(par,defpar);


%     for k=1:length(f)
%         [img,dimes,vox] = read_avw(deblank(f{k}));
%
%         vol(k,1) = length(find(img>seuil));
%         vol(k,2) = vol(k,1) * prod(vox(1:3));
%         volmean=0;
%     end


switch nargout
    case 1
        opt = '-n -V ';
    case 2
        opt = '-n -V -M ';
    case 3
        opt = '-n -V -M -S ';
    case 4
        opt = '-n -V -M -S -E';
    case 5
        opt = '-n -V -M -S -E -P 98';
end

if ~isempty(par.lthr)
    opt = sprintf('-l %f %s',par.lthr,opt);
end
if ~isempty(par.uthr)
    opt = sprintf('-u %f %s',par.uthr,opt);
end
if par.abs
    opt = sprintf('-a  %s',opt);
end

if ~isempty(par.mask)
    opt = sprintf(' -k %s %s ',par.mask,opt);
end

for k=1:length(f)
    
    cmd = sprintf('fslstats %s %s',f{k},opt);
    
    [a,b]=unix(cmd);
    b = str2num(b);
    
    if isempty(b)
        b=ones(1,6)*NaN;
    end
    vol(k,:) = b(1:2);
    
    if nargout>=2
        volmean(k,:) = b(3);
    end
    
    if nargout>=3
        volstd(k,:)  = b(4);
    end
    
    if nargout>=4
        volentropy(k,:) = b(5);
    end
    
    if nargout>=5
        vol98pecentil(k,:) = b(6);
    end
    
    
end

if exist('volmean','var'), varargout{1} = volmean;end
if exist('volstd','var'), varargout{2} = volstd;end
if exist('volentropy','var'), varargout{3} = volentropy;end
if exist('vol98pecentil','var'),varargout{4} = vol98pecentil;end




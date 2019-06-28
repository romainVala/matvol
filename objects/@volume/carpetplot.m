function carpetplot( volumeArray, keep_nVoxels, keep_nPC )

if ~exist('keep_nVoxels','var'), keep_nVoxels = 1e3; end
if ~exist('keep_nPC'    ,'var'), keep_nPC     = 50;  end


for vol = 1 : numel(volumeArray)
    
    line = 1; % first volume only
    
    %% Load
    
    % Load volume with SPM
    V = spm_vol(volumeArray(vol).path(line,:));
    for i = 2 : length(V)
        V(i).mat = V(1).mat;
    end
    Y = spm_read_vols(V);
    clear V % release memory
    
    
    %% Carpetplot
    
    % Timeseries of each voxel : 1 line == 1 voxel timeserie
    Y = reshape(Y,[],size(Y,4))';
    
    % Detrend &
    Y = detrend(Y);
    Ymean = mean(Y);
    Ystd  = mean(Y);
    
    % Reorder by std, and only keep the top voxels
    [~,order] = sort(Ystd,'descend');
    Y     = Y    (:,order); Y     = Y    (:,1:keep_nVoxels);
    Ymean = Ymean(:,order); Ymean = Ymean(:,1:keep_nVoxels);
    Ystd  = Ystd (:,order); Ystd  = Ystd (:,1:keep_nVoxels);
    
    % Standardize (z-value)
    Ynormalized = (Y - Ymean)./Ystd;
    clear Y
    
    % remove voxel with a NaN inside (pb with data?)
    hasNan_hasInf = isnan(Ynormalized) | isinf(Ynormalized);
    Ynormalized(:,any(hasNan_hasInf)) = [];
    clear hasNan_hasInf
    
    
    %% PCA
    
    [m,n]=size(Ynormalized);
    [Us,S,EVec] = svd(Ynormalized,0);
    if m == 1
        S = S(1);
    else
        S = diag(S);
    end
    Eload = Us .* repmat(S',m,1);
    S = S ./ sqrt(m-1);
    if m <= n
        S(m:n,1) = 0;
        S(:,m:n) = 0;
    end
    EVal = S.^2;
    Eload = Eload(:,1:keep_nPC); % keep the PCs, which explain the most variance
    
    
    %% Plot
    
    figure('Name',volumeArray(vol).path(line,:),'NumberTitle','off');
    colormap(gray)
    ax(1) = subplot(2,1,1);
    image(Ynormalized','CDataMapping','scaled')
    title('fmri Volume')
    xlabel('volume index')
    ylabel('voxel index')
    ax(2) = subplot(2,1,2);
    image(Eload','CDataMapping','scaled')
    title('Pricipal componets, top to bottom is the the variance explained')
    xlabel('volume index')
    ylabel('PC index')
    linkaxes(ax,'x')
    drawnow
    
    
end % vol

end % function

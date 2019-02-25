function carpetplot( volumeArray )

for vol = 1 : numel(volumeArray)
    
    for line = 1 %: size(volumeArray(vol).path,1)
        
        % Load volume with SPM
        V = spm_vol(volumeArray(vol).path(line,:));
        for i = 2 : length(V)
            V(i).mat = V(1).mat;
        end
        Y = spm_read_vols(V);
        clear V % release memory
        
        % Prep figure
        figure('Name',volumeArray(vol).path(line,:),'NumberTitle','off');
        colormap(gray)
        
        % Timeseries of each voxel : 1 line == 1 voxel timeserie
        Y = reshape(Y,[],size(Y,4));
        
        Y = spm_detrend(Y')';        % detrend
        Y = Y./max(abs(Y),[],2)*100; % normalize in (%)
        Y(all(isnan(Y),2),:) = [];   % remove empty lines (pb with data?)
        Y(isnan(Y)) = 0;             % change NaN->0 (for the color)
        
        ax(1) = subplot(2,1,1);
        image(Y,'CDataMapping','scaled')
        title('fmri Volume')
        xlabel('volume index')
        ylabel('voxel index')
        drawnow
        
        
        % COEFF = [nVolumes, nPCs]  principal components (PCs) ordered by variance
        %                           explained
        % SCORE = [nVoxel, nPCs]    loads of each component in each voxel, i.e.
        %                           specific contribution of each component in
        %                           a voxel's variance
        % LATENT = [nPCs, 1]        eigenvalues of data covariance matrix,
        %                           stating how much variance was explained by
        %                           each PC overall
        % TSQUARED = [nVoxels,1]    Hotelling's T-Squared test whether PC
        %                           explained significant variance in a voxel
        % EXPLAINED = [nPCs, 1]     relative amount of variance explained (in
        %                           percent) by each component
        % MU = [1, nVolumes]        mean of all time series
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(Y);
        COEFF = COEFF';
        ax(2) = subplot(2,1,2);
        image(COEFF(1:end,:),'CDataMapping','scaled')
        title('Pricipal componets, top to bottom is the the variance explained')
        xlabel('volume index')
        ylabel('PC index')
        
        linkaxes(ax,'x')
        drawnow
        
    end % line
    
end % vol

end % function

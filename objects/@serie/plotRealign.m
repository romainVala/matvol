function plotRealign( serieArray )
% PLOTREALIGN plots the realignment paramters for EPI sequences
% Plots all series for each exam


%% plotRealign

for ex = 1 : size(serieArray,1)
    
    rp = zeros(0,6);
    
    % Fetch rp data
    for ser = 1 : size(serieArray,2)
        
        try
            rp_file = get_subdir_regex_files(serieArray(ex,ser).path,'^rp_.*.txt$',struct('verbose',0,'wanted_number_of_file',1)); % error from this function if not found
            current_rp = load(rp_file{1});
            if ser > 1
                rp = [ rp ; rp(end,:) + current_rp ]; %#ok<*AGROW>
            else
                rp = [ rp ; current_rp ];
            end
            
        catch
            % When volumes are not found
            warning('Could not find realignment paramters in %s ', serieArray(ex,ser).path )
            
        end
        
    end
    
    if size(rp,1) > 0
        
        % Plot
        figure('Name',serieArray(ex,ser).exam.name,'NumberTitle','off')
        fprintf('[plotRealign]: Plotting %s \n', serieArray(ex,ser).exam.name)
        for ser = 1 : size(serieArray,2)
            fprintf('[plotRealign]:          %s \n', serieArray(ex,ser).name)
        end
        
        % translation
        subplot(2,1,1);
        plot(rp(:,1:3))
        axis tight
        ylabel('translation in mm')
        xlabel('image')
        legend('x','y','z','location','best')
        
        % rotation
        subplot(2,1,2);
        plot(rp(:,4:6)*180/pi)
        axis tight
        ylabel('rotation in °')
        xlabel('image')
        legend('pitch','roll','yaw','location','best')
        
    end
    
end

end % function

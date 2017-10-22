% % % % % % % % % % % % % % % % % % % % % % % % % 
% Mental rotation task
% Author: Jörn Alexander Quent (alexander.quent@rub.de)
% Version: 1.11 22. October 2017
% % % % % % % % % % % % % % % % % % % % % % % % % 

try
    % Preliminary stuff
    % Clear Matlab/Octave window:
    clc;
    
    % Reseed randomization
    rand('state', sum(100*clock));
    
    % check for Opengl compatibility, abort otherwise:
    AssertOpenGL;
    Priority(2);
    
    % General information about subject and session
    subNo = input('Subject number: ');
    hand  = input('Condition code: ');
    date  = str2num(datestr(now,'yyyymmdd'));
    time  = str2num(datestr(now,'HHMMSS'));
    
    % Get information about the screen and set general things
    Screen('Preference', 'SuppressAllWarnings',1);
    Screen('Preference', 'SkipSyncTests', 1);
    screens       = Screen('Screens');
    if length(screens) > 1
        error('Multi display mode not supported.');
    end
    rect          = Screen('Rect',0);
    screenRatio   = rect(3)/rect(4);
    pixelSizes    = Screen('PixelSizes', 0);
    startPosition = round([rect(3)/2, rect(4)/2]);
    HideCursor;
    
    % Experimental variables
    % Number of trials etc.
    degrees        = [0 60 120 180 240 300];
    nExercise      = 40;
    numberOfBlocks = 2;
    trialList      = [];
    for i = 1:20
        if i < 12
            mirror = 0;
        else
            mirror = 1;
        end
        trialList = [trialList [zeros(1, length(degrees))+i; degrees; zeros(1, length(degrees))+ mirror]]; % [stimulus; degress; mirroring] if stimulus > 10 then it is mirrored
    end
    
    % Output files
    datafilename = strcat('results/mentalRotation_',num2str(subNo),'.dat'); % name of data file to write to
    mSave        = strcat('results/mentalRotation_',num2str(subNo),'.mat'); % name of another data file to write to (in .mat format)
    mSaveAll     = strcat('results/mentalRotation_',num2str(subNo),'All.mat'); % name of another data file to write to (in .mat format)
    
    % Checks for existing result file to prevent accidentally overwriting
    % files from a previous subject/session (except for subject numbers > 99):
    if subNo<99 && fopen(datafilename, 'rt')~=-1
        fclose('all');
        error('Result data file already exists! Choose a different subject number.');
    else
        datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing
    end
    
    % Temporal variables
    ITI                 = 0.25;
    fixDuration         = 0.25; % as in Shepard (1971)
    maxDuration         = 8;
    fbTime              = 0.5;
    
    % Experimental data
    RT                  = zeros(2, length(trialList))-99;
    response            = zeros(2, length(trialList))-99;
    correctness         = zeros(2, length(trialList))-99;
    results             = cell(length(trialList)*numberOfBlocks, 14); 
    % SubNo, date, time, trial, stim, block, mirroring/rightAnswer,
    % response, correctness, RT, fixationOnsetTime, StimulusOnsetTime, endStimulus

    % Colors
    bgColor             = [255, 255, 255];
    fixColor            = [0 0 0];
    
    % Textures
    fixLen              = 20; % Size of fixation cross in pixel
    fixWidth            = 3;
    
    % Creating screen etc.
    try
        [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
    catch
        try
            [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
        catch
            try
                [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
            catch
                try
                    [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
                catch
                    [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
                end
            end
        end
    end
    center              = round([rect(3) rect(4)]/2);
    
    % Keys and responses
    KbName('UnifyKeyNames');
    space               = KbName('space');
    if hand == 1
            notMirrored         = KbName('RightArrow'); % Saying not mirrored
            mirrored            = KbName('LeftArrow');  % Saying mirrored
            notMirroredString   = 'rechte';
            mirroredString      = 'linke';
    elseif hand == 2
            notMirrored         = KbName('LeftArrow'); % Saying not mirrored
            mirrored            = KbName('RightArrow');  % Saying mirrored
            notMirroredString   = 'linke';
            mirroredString      = 'rechte';
    end
    
    % Loading stimuli
    images              = {};
    stimuli             = {};
    for i = 1:20
        if i > 10
            images{i}  = imread(strcat('stimuli/stim_',num2str(i),'.jpg'));
        else
            images{i}  = imread(strcat('stimuli/stim_',num2str(i),'.jpeg'));
        end
        stimuli{i} = Screen('MakeTexture', myScreen, images{i}); % Saving textures in this structure
    end
    imageSize          = size(images{1});
    shift              = 50;
    
    % Calculating to rectangles (splitting screen)
    leftPosition       = [center(1)-imageSize(1)-shift center(2)-imageSize(1)/2 center(1)-shift center(2)+imageSize(1)/2];
    rightPosition      = [center(1)+shift center(2)-imageSize(1)/2 center(1)+ imageSize(1)+shift center(2)+imageSize(1)/2];
    
    % Message for introdution
    lineLength   = 70;
    Screen('TextStyle', myScreen, 1)
    messageIntro = WrapString(horzcat('Mentale Rotationsaufgabe \n\n In dieser Aufgabe werden Ihnen in jedem Durchgang zwei geometrische Figuren gezeigt. Die Figur auf der rechten Seite wird um die eigene Achse rotiert. Wenn Sie die rechte Figur mental rotieren und mit der linken vergleichen, kann es entweder sein, dass die Figuren Spiegelbilder von einander oder sie deckungsgleich sind. Wenn eine Figur gespiegelt wurde, drücken Sie bitte die ', mirroredString, ' Pfeiltaste. Wenn beide Figuren nach der Rotation identisch sind (sprich: nicht gespiegelt), drücken Sie bitte die ', notMirroredString, ' Pfeiltaste. Jeder Durchgang beginnt mit der Präsentation eines Kreuzes in der Mitte des Bildschirms. Bitte fixieren Sie dieses mit Ihrem Blick. Danach werden die beiden Figuren eingeblendet und Sie können Ihre Antwort geben. Bitte antworten Sie so schnell und so akkurat wie möglich. Die Aufgabe ist in eine kurze Übungsphase und zwei gleichgroße Blöcke eingeteilt. Die Pause zwischen den Blöcken sollte zur Erholung genutzt werden.\n\n Drücken Sie bitte die Leertaste, um mit der Übungsphase zu beginngen.'),lineLength);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Experimental loop
    iTrial = 0; % used for index
    for block = 1:numberOfBlocks
        if block == 1 % Shows introduction
            DrawFormattedText(myScreen, messageIntro, 'center', 'center');
            Screen('Flip', myScreen);
            [secs, keyCode] = KbWait;
            while keyCode(space) == 0
                [secs, keyCode] = KbWait;
            end
            
            WaitSecs(0.1);
            DrawFormattedText(myScreen, 'Übung \n Bitte Leertaste drücken!', 'center', 'center');
            Screen('Flip', myScreen);
            [secs, keyCode] = KbWait;
            while keyCode(space) == 0
                [secs, keyCode] = KbWait;
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Exercise 
            trialListExp = trialList(1:3, randomOrder(length(trialList), nExercise));
            for trial = 1:nExercise
                % Fixation cross
                Screen('FillRect', myScreen, bgColor(1, 1:3)); % Sets normal bg color
                Screen('DrawLine', myScreen, fixColor, center(1)- fixLen, center(2), center(1)+ fixLen, center(2), fixWidth);
                Screen('DrawLine', myScreen, fixColor, center(1), center(2)- fixLen, center(1), center(2)+ fixLen, fixWidth);
                [VBLTimestamp fixationOnsetTime] = Screen('Flip', myScreen);
                WaitSecs(fixDuration);

                % Stimulus presentation
                if trialListExp(1,trial) > 10
                    Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)-10},[] , leftPosition, 0); % Stimulus for comparison
                else
                    Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)},[] , leftPosition, 0); % Stimulus for comparison
                end
                Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)},[] , rightPosition, trialListExp(2, trial)); % stimulus rotated
                [VBLTimestamp StimulusOnsetTime1] = Screen('Flip', myScreen);

                % Recording response
                [keyIsDown, secs, keyCode] = KbCheck; % saves whether a key has been pressed, seconds and the key which has been pressed.
                while keyCode(notMirrored) == 0 && keyCode(mirrored) == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if secs - StimulusOnsetTime1 >= maxDuration
                        break
                    end
                end
                endStimulus   = Screen('Flip', myScreen);
                
                % Feedback
                if keyCode(notMirrored) == 1 % Saying not mirrored
                    if trialListExp(3, trial) == 0 % Not mirrored
                        Screen('TextColor', myScreen, [0 255 0]); 
                        DrawFormattedText(myScreen, horzcat('richtig'), 'center', 'center');
                    else % Mirrored
                        Screen('TextColor', myScreen, [255 0 0]); 
                        DrawFormattedText(myScreen, horzcat('falsch'), 'center', 'center');
                    end
                elseif keyCode(mirrored) == 1 % Saying mirrored
                    if trialListExp(3, trial) == 0 % Not mirrored
                        Screen('TextColor', myScreen, [255 0 0]); 
                        DrawFormattedText(myScreen, horzcat('falsch'), 'center', 'center');
                    else % Mirrored
                        Screen('TextColor', myScreen, [0 255 0]); 
                        DrawFormattedText(myScreen, horzcat('richtig'), 'center', 'center');
                    end 
                end
                Screen('Flip', myScreen);
                WaitSecs(fbTime);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Start of Experiment display
            Screen('TextColor', myScreen, [0 0 0]); 
            WaitSecs(0.1);
            DrawFormattedText(myScreen, horzcat('Beginn des Experiments. Bitte Leertaste drücken!'), 'center', 'center');
            Screen('Flip', myScreen);
            [secs, keyCode] = KbWait;
            while keyCode(space) == 0
                [secs, keyCode] = KbWait;
            end
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Experiment 
        trialListExp = trialList(1:3, randomOrder(length(trialList), length(trialList)));
        
        % Block display
        WaitSecs(0.1);
        DrawFormattedText(myScreen, horzcat(num2str(block),'. Block \n Bitte Leertaste drücken! Dann geht das Experiment weiter.'), 'center', 'center');
        Screen('Flip', myScreen);
        [secs, keyCode] = KbWait;
        while keyCode(space) == 0
            [secs, keyCode] = KbWait;
        end
        Screen('Flip', myScreen);
        
        % Experimental loop
        for trial = 1:length(trialListExp)
            startOfTrial = GetSecs;
            iTrial = iTrial + 1;
            
            % Fixation cross
            Screen('DrawLine', myScreen, fixColor, center(1)- fixLen, center(2), center(1)+ fixLen, center(2), fixWidth);
            Screen('DrawLine', myScreen, fixColor, center(1), center(2)- fixLen, center(1), center(2)+ fixLen, fixWidth);
            [VBLTimestamp fixationOnsetTime] = Screen('Flip', myScreen);
            WaitSecs(fixDuration);

            % Stimulus presentation
            if trialListExp(1,trial) > 10
                Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)-10},[] , leftPosition, 0); % Stimulus for comparison
            else
                Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)},[] , leftPosition, 0); % Stimulus for comparison
            end
            Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)},[] , rightPosition, trialListExp(2, trial)); % stimulus rotated
            [VBLTimestamp StimulusOnsetTime1] = Screen('Flip', myScreen);
            
            % Recording response
            [keyIsDown, secs, keyCode] = KbCheck; % saves whether a key has been pressed, seconds and the key which has been pressed.
            while keyCode(notMirrored) == 0 && keyCode(mirrored) == 0
                [keyIsDown, secs, keyCode] = KbCheck;
                if secs - StimulusOnsetTime1 >= maxDuration
                    break
                end
            end
            endStimulus   = Screen('Flip', myScreen);
            
            % Saving response and checking correctness
            RT(block, trial) = (secs - StimulusOnsetTime1)*1000;
            if keyCode(notMirrored) == 1 % Saying not mirrored
                response(block, trial) = 0; % Saying not mirrored
                if trialListExp(3, trial) == 0 % Not mirrored
                    correctness(block, trial) = 4; % Correct rejection
                else % Mirrored
                    correctness(block, trial) = 3; % Miss
                end
            elseif keyCode(mirrored) == 1 % Saying mirrored
                response(block, trial) = 1; % Saying mirrored
                if trialListExp(3, trial) == 0 % Not mirrored
                    correctness(block, trial) = 2; % False Alarm
                else % Mirrored
                    correctness(block, trial) = 1; % Hit
                end 
            end
            WaitSecs(ITI);
            
            % SubNo, date, time, trial, stim, block, angle, mirroring/rightAnswer,
            % response, correctness, RT, fixationOnsetTime, StimulusOnsetTime, endStimulus
            fprintf(datafilepointer,'%i %i %i %i %i %i %i %i %i %i %f %f %f %f\n', ...
                subNo, ...
                date, ...
                time, ...
                iTrial, ...
                trialListExp(1,trial), ...
                block, ...
                trialListExp(2, trial),...
                trialListExp(3,trial), ...
                response(block, trial),...
                correctness(block, trial),...
                RT(block, trial),...
                (fixationOnsetTime - startOfTrial)*1000,...
                (StimulusOnsetTime1 - startOfTrial)*1000,...
                (endStimulus - startOfTrial)*1000);

            results{iTrial, 1}  = subNo;
            results{iTrial, 2}  = date;
            results{iTrial, 3}  = time;
            results{iTrial, 4}  = iTrial;
            results{iTrial, 5}  = trialListExp(1,trial);
            results{iTrial, 6}  = block;
            results{iTrial, 7}  = trialListExp(2, trial);
            results{iTrial, 8}  = trialListExp(3,trial);
            results{iTrial, 9}  = response(block, trial);
            results{iTrial, 10} = correctness(block, trial);
            results{iTrial, 11} = RT(block, trial);
            results{iTrial, 12} = (fixationOnsetTime - startOfTrial)*1000;
            results{iTrial, 13} = (StimulusOnsetTime1 - startOfTrial)*1000;
            results{iTrial, 14} = (endStimulus - startOfTrial)*1000;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    
    % End screen
    DrawFormattedText(myScreen, 'Ende. Bitte Leertaste drücken!', 'center', 'center');
    Screen('Flip', myScreen);
    [secs, keyCode] = KbWait;
    while keyCode(space) == 0
        [secs, keyCode] = KbWait;
    end
    
    save(mSave, 'results');
    save(mSaveALL);
    fclose('all');
    Screen('CloseAll');
    Priority(0);
    ShowCursor;
catch
    rethrow(lasterror)
    save(mSave, 'results');
    save(mSaveAll);
    Screen('CloseAll')
    fclose('all');
    Priority(0);
    ShowCursor;
end
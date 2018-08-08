function [rndm] = randomOrder(numitems,len,varargin)

% function [rndm] = randomOrder(numitems,len,varargin)
%
% This function is used to generate a vector of random numbers with length
% len and the values 1:numitems.  Randomization can be controlled by
% optional arguments.
%
% INPUTS
%   * numitems      : number of items (eg. stimuli) to be randomized
%   * len           : length of matrix (eg. number of trials)
%
% INPUTS-OPTIONAL
%  * 'ratio'        : Vector, used to specify the ratio of randomized
%                   : items. Values between 0-1. All entries must add up
%                   : to 1. Make sure that the ratio is compatible with the
%                   : default value for 'maxRepeat'(3). Using this argumnet
%                   : will cause a warning, to disable it, add the argument
%                   : 'NoWarning'.
%
%  * 'maxRepeat'    : Specifies the maximal number of repetitions of each
%                   : item. Default is 3. Setting this value too low can
%                   : lead to uniformity of the output. Using this argumnet
%                   : will cause a warning, to disable it, add the argument
%                   : 'NoWarning'.
%
%  * 'boolean'      : Returns boolean vector, not values (1:numitems). Using
%                   : this paramater will issue a warning when numitems is
%                   : bigger than 2. To disable it, add the argument
%                   : 'NoWarning'.
%
%  * 'normalized'   : Returns vector of random numbers chosen from a normal
%                   : distribution with mean MU and standard deviation
%                   : SIGMA. Nesessary additional arguments: mu and sigma
%                   : The first argument "numitems" has no effect for
%                   : this argument!!! Any number is fine!!!
%
%  * 'maxTries'     : Specifies the maximal number of tries to comply with
%                   : the criteia. Default is 50. Some criteria can be hard
%                   : to match,setting this value very high prevents the
%                   : function from terminating with an error when the
%                   : criteria are set very restrictive, but it can
%                   : seriously affect performance. Usually the criteria
%                   : for the random vector should be reconsidered rather
%                   : than this value be adjusted.
% OUTPUTS
%  * rndm           : randomized vector
%
% EXAMPLES
% 1.
%   randomOrder(2,6)
%   ans = [2 1 1 2 1 2]
% 2.
%   randomOrder(2,10,'ratio',[.1 .9],'maxrepeat',10)
%   ans = [2 2 1 2 2 2 2 2 2 2]
% 3.
%   randomOrder(2,6,'maxRepeat',1)
%   ans = [1 2 1 2 1 2]
% 4.
%   randomOrder(2,6,'boolean')
%   ans = [0 1 0 0 1 1]
% 5.
%   randomOrder(3,9)-1 % when values between 0 and 2 are required
%   ans = [2 1 2 0 2 0 0 1 1]
% 6.
%   randomOrder(1,5,'normalized',2,1)
%   ans = [2.0554  3.2538  -0.5200  2.5849  0.9919]
%
% Copyright 2007-2010
% CC-GNU GPL by attribution
% Please cite the BioPsychology Toolbox where this function is used.
%       http://sourceforge.net/projects/biopsytoolbox/
%
% See also:  randperm, rand, randn

% VERSION HISTORY:
% Author:         Tobias Otto, Jonas Rose
% Version:        1.3
% Last Change:    25.10.2010
%
% 18.04.2008: jonas: decumentation, headerTemplate
% 28.05.2008: jonas: debugged 'boolean', added example
% 09.06.2008: Tobias: change in help
% 11.06.2008: jonas: change in help, extended error randomization is not possible
% 23.06.2008: jonas:  now generating a single randomNumber is allowed.
% 02.07.2009, Jonas: Bugfix for boolean switch
% 25.10.2010, Tobias: makes sure that vec contains all values from 1:n    
% 04.02.2011, Jonas: Bugfix, floating point precision in 'ratio'     

%% BUGS/ TODO

%% Set new state for rand !!!
%Check MATLAB version
%tmp                         = version('-release');
%tmp(~ismember(tmp,'0':'9')) = [];

%if(str2double(tmp) <= 2008)
%    rand('state',sum(100*clock));
%else
%    RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));
%end

%% Initializations
global CONSEC

% each item is presented maximal 3 times in a row
CONSEC    = 3;
% each item is presented equally often
ratio       = repmat(1/numitems,1,numitems);
maxPrec     = 1000000; % the maximal precison of ratio is 1/maxPrec
% max number of tries to produce a vector that fits the criteria is 50
maxtries    = 50;
% function retuns values between 1:n if true 0:1
noindices   = 0;
% Create random numbers using a normal distribution
normalized  = 0;
% warn the user if maxrepeat is used
nowarning   = false;
% don't warn unless the values for ratio or maxrepeat are adjusted
warn        = false;
% Necessary if function is called twice
pause(500e-6)

%% get the variable input arguments and change the defaults
if nargin > 1
    i=1;
    while(i<=length(varargin))
        switch lower(varargin{i})
            case 'ratio'
                ratio       = varargin{i+1};
                warn        = true;
                i           = i+2;
            case 'maxtries'
                maxtries    = varargin{i+1};
                i           = i+2;
            case 'maxrepeat'
                CONSEC      = varargin{i+1};
                warn        = true;
                i           = i+2;
            case 'boolean'
                noindices   = 1;
                i           = i+1;
            case 'nowarning'
                nowarning   = true;
                i           = i+1;
            case 'normalized'
                normalized  = 1;
                mu          = varargin{i+1};
                sigma       = varargin{i+2};
                i           = i+3;
            otherwise
                disp(['Unknown argument: ' varargin(i)]);
                i = i+1;
        end
    end
end
if sum(ratio) < .99
    error('Argumnets in ''Ratio'' don''t add up to 1.0.');
end
if ~nowarning && warn
    warning('BioBox:rand','Setting ''maxrepeat'' or ''ratio'' to funny values can increase uniformity of the generated matrix.');
end

%% generate and order random-matrix
rndm = 0;

if(~normalized)
    for j=1:maxtries+1
        if ~rndm                        % if findMatch was unsucessful
            tmp  = cell(1,numitems);
            for i=1:numitems
%                  tmp{i} = repmat(i,1,ceil(len*ratio(i)));
    			tmp{i} = repmat(i,1,ceil(round(len*ratio(i)*maxPrec)/maxPrec));
            end
            rndm = cell2mat(tmp);
            
            % randomize the items
            rndm = rndm(randperm(length(rndm)));
            
            % Check, if vector contains all values from 1:n
            if(len >= numitems)
                [tmp,index] = unique(rndm,'first');
                tmp         = rndm(index);
                rndm(index) = [];
                rndm        = [tmp rndm(1:len-length(index))];
                % randomize the items
                rndm        = rndm(randperm(length(rndm)));
            else
                rndm = rndm(1:len);
            end
        else
            break
        end
        rndm = findMatch(rndm,1,0);
    end
else
    % Normalized sistribution
    if(any(sigma < 0))
        error('Argument ''sigma'' in normalized is smaller than zero!');
    end
    rndm = randn(1,len) .* sigma + mu;
end

if (length(rndm) == 1) && ~(len==1)
    error('error:RndOrder','RandomOrder.m was unable to randomize the items with the specified parameters. \n ...Check that ''maxRepeat'', ''ratio'' and ''maxTries'' make sense ')
end

% Reformat values to boolean.
if noindices
    if any(rndm>2) && ~nowarning
        warning('All values bigger than 2 were converted to ''true''');
    end
    rndm = logical(rndm>1);
end


%% SUBFUNCTIONS

%% findMatch
function rndm = findMatch(rndm,ind,matches)
% a recursive subfunction to eliminate repetitions
global CONSEC;                                  % max acceptable repetitions
if length(rndm) == ind;                         % end recursion at end of matrix
    return;
elseif rndm(ind) ~= rndm(ind+1);                % no repetition
    rndm = findMatch(rndm,ind+1,0);             % keep searching for repetitions
elseif rndm(ind) == rndm(ind+1) && ...           % found a repetition &
        matches >= CONSEC-1;                  % too many repetitions
    rndm = swapper(rndm,ind+1);                 % the swapping of elements
    if length(rndm) == 1                                   % if swapper can't fix the problem, return
        return;
    end
    rndm = findMatch(rndm,ind+1,0);             % keep going
elseif rndm(ind) == rndm(ind+1);                % found a repetition
    rndm = findMatch(rndm,ind+1,matches+1);     % count the repetition and keep searching
end

%% swapper
function rndm = swapper(rndm,ind)
% if we tried swapping to often, or are at the end, we stop trying
if ind >= length(rndm)
    rndm = 0;
    return
end
% find elements above ind that are unequal to rndm(ind)
indb = find(rndm(ind+1:end)~=rndm(ind));
% swap with the first element that was found
if isempty(indb)
    rndm = 0;
    return
else
    tmp                 = rndm(indb(1)+ind);
    rndm(indb(1)+ind)   = rndm(ind);
    rndm(ind)           = tmp;
end

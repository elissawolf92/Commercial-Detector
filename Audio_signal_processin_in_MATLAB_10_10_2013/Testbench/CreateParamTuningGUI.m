function hMainFigure = CreateParamTuningGUI(varargin)
%CREATEPARAMTUNINGGUI Interactively tune parameters of System
%                           objects
% Function to create a GUI to tune parameters of System objects. Sliders
% are created for the parameters and can be used to change the parameter
% values while streaming data to the System objects. Edit boxes placed to
% the right of the sliders show the current value of the slider and can
% also be used to type in the new values. Labels to the left of sliders
% denote the parameter name. The GUI also has buttons to reset the System
% object or to stop the simulation. Communication between the GUI and the
% code that runs the simulation is performed using UDP.
%
% The GUI can also synchronize with a MIDI control. The sliders and buttons
% have context menus, available when you right-click on them. When the user
% selects the context menu, a dialog is opened to let the user choose a
% MIDI control.  The chosen MIDI control is then cross-wired with the
% uicontrol so that operating one control is tracked by the other control.
%
% Inputs:
%       parameters  -  Array of structures for parameters that need to be
%                      tuned. Each structure can have three fields:
%                      * Name - String which will be displayed to the left
%                      of the slider. Default values are 'Parameter 1',
%                      'Parameter 2', and so on
%                      * Limits - Vector of two elements that correspond to
%                      minimum and maximum values for the sliders. Default
%                      value is [0, 1]
%                      * InitialValue - Scalar that is the initial position
%                      of the slider. This must be a value within the
%                      limits. Default value is the average of the two
%                      limit values
%       title       -  String that is displayed as the title of the GUI.
%                      This input is optional
% Output:
%       hMainFigure -  Handle to the GUI figure
%
% Example:
%         % Create a GUI with two sliders
%         param = struct([]);
%         param(1).Name = 'First parameter';
%         param(1).InitialValue = 20;
%         param(1).Limits = [0, 400];
%         param(2).Name = 'Second parameter';
%         param(2).InitialValue = 0.3;
%         CreateParamTuningGUI(param, ...
%                                   'Example to show parameter tuning GUI')
%
% A complete working example with a System object is present in the help
% for the helper function UnpackUDP

% Copyright 2013 The MathWorks, Inc.

%% Validate inputs
% Find out number of parameters
narginchk(1, 2);    % title input is optional
parameters = varargin{1};
if nargin == 2
    title = varargin{2};
else
    title = getString(message('dsp:demo:GUITitle'));
end
nParams = length(parameters);
parameters = checkInputs(parameters); % validate inputs and add default values

%% Handles for GUI objects and UDP System object
% Declare and create all the UI objects in this GUI here so that they can
% be used in any functions
hMainFigure    =   figure(...       % the main GUI figure
                        'Name', title, ...
                        'MenuBar','none', ...
                        'Toolbar','none', ...
                        'HandleVisibility','callback', ...
                        'NumberTitle','off', ...
                        'Color', get(0, 'defaultuicontrolbackgroundcolor'),...
                        'DeleteFcn', @hFigDeleteCallback);
hSlider = zeros(nParams,1);
hParamNames = zeros(nParams,1);
hParamValues = zeros(nParams,1);
sliderVal = zeros(nParams, 1);
sliderHeight = min(0.85/(2*nParams+1), 0.08);
for idx = 1:nParams
    param = parameters(idx);
    hSlider(idx)    =   uicontrol(...    % Slider values for parameters
                            'Parent', hMainFigure, ...
                            'Units','normalized',...
                            'Position',[0.2, 1-2*idx*sliderHeight, ...
                                        0.6, sliderHeight],...
                            'HandleVisibility','callback',...
                            'Style','slider', ...
                            'Min', param.Limits(1),...
                            'Max', param.Limits(2),...
                            'Value', param.InitialValue,...
                            'Tag', ['Slider ', int2str(idx)],...
                            'Callback', @hSliderCallback);
    learnMIDIControl(hSlider(idx)); % Register the slider for MIDI control
    
    hParamNames(idx)=   uicontrol(...   % Label for parameter names to the left of sliders
                            'Parent', hMainFigure, ...
                            'Units','normalized',...
                            'Position',[0,   1-(2*idx+0.3)*sliderHeight, ...
                                        0.2, sliderHeight],...
                            'HandleVisibility','callback', ...
                            'String',param.Name,...
                            'FontUnits', 'normalized',...
                            'FontSize', 0.4,...
                            'Style','text');
    hParamValues(idx)=   uicontrol(...   % Edit box for parameter values to the right of sliders
                            'Parent', hMainFigure, ...
                            'Units','normalized',...
                            'Position',[0.82, 1-(2*idx)*sliderHeight, ...
                                        0.16, sliderHeight],...
                            'HandleVisibility','callback', ...
                            'BackgroundColor', [1 1 1], ...
                            'String',num2str(param.InitialValue),...
                            'FontUnits', 'normalized',...
                            'FontSize', 0.4,...
                            'Style','edit', ...
                            'Tag', ['Edit ', int2str(idx)],...
                            'Callback', @hParamValuesCallback);
    sliderVal(idx) =   param.InitialValue; % Used to roll back value when edit box value is not in limits
end
% hReset          =   uicontrol(...    % button to reset the System object 
%                         'Parent', hMainFigure, ...
%                         'Units','normalized',...
%                         'HandleVisibility','callback', ...
%                         'Position',[0.1 0.05 0.1 sliderHeight],...
%                         'String','Reset',...
%                         'FontUnits', 'normalized',...
%                         'FontSize', 0.4,...
%                         'Callback', @hResetButtonCallback);
% learnMIDIControl(hReset);   % Register the button for MIDI control

hPauseSim          =   uicontrol(...    % button to reset the System object 
                        'Parent', hMainFigure, ...
                        'Units','normalized',...
                        'HandleVisibility','callback', ...
                        'Position',[0.25 0.05 0.3 sliderHeight],...
                        'String','Pause',...
                        'FontUnits', 'normalized',...
                        'FontSize', 0.4,...
                        'Callback', @hPauseSimButtonCallback);
learnMIDIControl(hPauseSim);   % Register the button for MIDI control

hStopSim        =   uicontrol(...    % button to stop the simulation  
                        'Parent', hMainFigure, ...
                        'Units','normalized',...
                        'HandleVisibility','callback', ...
                        'Position',[0.6 0.05 0.3 sliderHeight],...
                        'String','Stop',...
                        'FontUnits', 'normalized',...
                        'FontSize', 0.4,...
                        'Callback', @hStopSimButtonCallback);  
learnMIDIControl(hStopSim); % Register the button for MIDI control

hUDP  = dsp.UDPSender;       % UDP sender System object
switchReset = false;         % Can be changed to reset the System object
flagPauseSim = false;        % Can be set to pause the simulation
flagStopSim = false;         % Can be set to stop the simulation

drawnow

%% Callback functions as nested functions

function hSliderCallback(hObject,~,~)
% Called when a slider value changes
    val = get(hObject,'Value');
    TagStr = get(hObject,'Tag');
    index = str2double(TagStr(end)); % This identifies the parameter number
    set(hParamValues(index), 'String', num2str(val));
    sliderVal(index) = val;
   
    sendUDP();
end

function hParamValuesCallback(hObject,~,~)
% Called when value in edit box changes

    TagStr = get(hObject,'Tag');
    index = str2double(TagStr(end)); % This identifies the parameter number
    try
        val = evalin('base',get(hObject,'String'));
        validateattributes(val, {'double', 'scalar'}, ... % check for new value to be in limit
            {'real', '>=',get(hSlider(index), 'Min'),'<=',get(hSlider(index), 'Max')})
    catch ME
        % Throw error on message box and revert to previous value on edit
        % box
        msgbox(ME.message, 'Error');
        set(hParamValues(index), 'String', num2str(sliderVal(index)));
        return;
    end
    
    set(hParamValues(index), 'String', num2str(val));
    set(hSlider(index), 'Value', val);
    sliderVal(index) = val;
    
    sendUDP();
end

function hResetButtonCallback(~,~,~)
% Called when "Reset" button is pressed
    switchReset = ~switchReset;
    sendUDP();
end

function hPauseSimButtonCallback(~,~,~)
% Called when "Stop Simulation" button is pressed
    if ~flagPauseSim
        set(hPauseSim, 'String', 'Resume');
    else
        set(hPauseSim, 'String', 'Pause');
    end
	flagPauseSim = ~flagPauseSim;
    sendUDP();
end

function hStopSimButtonCallback(~,~,~)
% Called when "Stop Simulation" button is pressed
    flagStopSim = true;
    sendUDP();
end

function hFigDeleteCallback(~,~,~)
% Called when the GUI is closed
    flagStopSim = true;   % Stop the simulation when GUI is closed
    sendUDP();
    release(hUDP);
end

function sendUDP()
    packetUDP = zeros(1,nParams+3);   % UDP packet contains slider values, reset flag, pause flag and stop simulation flag
    for index = 1:nParams
        packetUDP(index) = get(hSlider(index), 'Value');
    end
    packetUDP(end-2) = switchReset;
    packetUDP(end-1) = flagPauseSim;
    packetUDP(end)   = flagStopSim;
    step(hUDP,packetUDP);
    drawnow
end

end

%% validate inputs and add default values
function checkedInputs = checkInputs(inputs)
    checkedInputs = struct([]); % structure returned back
    nInputs = length(inputs);
    for index = 1:nInputs
        
        validateattributes(inputs(index), {'struct'}, {'nonempty'});
        
        if isfield(inputs(index), 'Name') && ...
                ~isempty(inputs(index).Name)
            % Name should be a string
            validateattributes(inputs(index).Name,...
                {'char'}, {'vector'}); 
            checkedInputs(index).Name = inputs(index).Name;
        else
            % Default value for Name
            checkedInputs(index).Name = ['Parameter ',int2str(index)];
        end
        
        if isfield(inputs(index), 'Limits') && ...
                ~isempty(inputs(index).Limits)            
             % Limits should be a vector of two numbers, and 
             % min should be less than max
            validateattributes(inputs(index).Limits,...
                {'numeric'}, {'real', 'increasing', 'vector', 'numel', 2}); 
            checkedInputs(index).Limits = inputs(index).Limits;
        else
            % Default value for Limits
            if isfield(inputs(index), 'InitialValue') &&...
                ~isempty(inputs(index).InitialValue)
                % if InitialValue is present
                checkedInputs(index).Limits = ...
                    [inputs(index).InitialValue-0.5, inputs(index).InitialValue+0.5];
            else
                checkedInputs(index).Limits = [0, 1];
            end
        end
        
        if isfield(inputs(index), 'InitialValue') &&...
                ~isempty(inputs(index).InitialValue)
            % Initial value should be a scalar number, and should be
            % between the limits
            validateattributes(inputs(index).InitialValue,...
                {'numeric'}, {'real', 'scalar', ...
                              '>=', checkedInputs(index).Limits(1), ...
                              '<=', checkedInputs(index).Limits(2)}); 
             checkedInputs(index).InitialValue = inputs(index).InitialValue;
        else
            % Default value for InitialValue is average of min and max
            checkedInputs(index).InitialValue = ...
               (checkedInputs(index).Limits(1)+checkedInputs(index).Limits(2))/2;
        end
    end
end

%% Functions for MIDI control
function learnMIDIControl(uihandle)
    % LEARNMIDICONTROL Enable uicontrol to synchronize with a MIDI control
    %
    % This will attach a context menu to uicontrol UIHANDLE.
    % When the user selects the context menu, a dialog is opened to let the
    % user choose a MIDI control.  The chosen MIDI control is then
    % cross-wired with the uicontrol so that operating one control is
    % tracked by the other control.
    %
    % Caveats: 
    %   1) Only bidirection MIDI controls can track a uicontrol.
    %
    %   2) Currently only sliders, togglebuttons, pushbuttons, and
    %      checkboxes are supported.
    %
    %   3) The cross-wiring hijacks the uicontrol's callback.  For this to
    %      work correctly, the uicontrol callback MUST be set before
    %      calling learnMIDIControl()
    %
    %   4) The MIDI control will invoke the uicontrol's callback with []
    %      for the 2nd argument (eventdata).  This is correct for genuine
    %      uicontrols (only the KeyPressFcn is passed non-empty eventdata).
    %      This may be an issue for a uibuttongroup if its callback relies
    %      on eventdata. 
    %

    
    type = get(uihandle,'Type');
    style = get(uihandle,'Style');
    
    assert(strcmpi(type,'uicontrol'), 'only supports uicontrols');

    assert(strcmpi(style,'slider') || ...
        strcmpi(style,'togglebutton') || ...
        strcmpi(style,'pushbutton') || ...
        strcmpi(style,'checkbox'), ...
        'only supports sliders, togglebuttons, pushbuttons, and checkboxes');
    
    % Save this asap before it has a chance to get lost.
    if isempty(getappdata(uihandle,'savedcallback'))
        % Setting this twice => inifinite recursion
        setappdata(uihandle,'savedcallback',get(uihandle, 'callback'));
    end
    
    prefname = getPrefName(uihandle);
    if ispref('midi', prefname)
        pref = getpref('midi',prefname);
        s = warning('off','dsp:midi:specifiedDeviceOpenFailed');
        crossWireMidicontrolToUicontrol(uihandle, pref.controlNumber, pref.deviceName);
        warning(s.state,s.identifier);
    end
    
    attachContextMenu(uihandle, prefname);
    
end

function prefname = getPrefName(uihandle)
    fig = ancestor(uihandle,'figure');
    prefname = genvarname([get(fig,'Name') '_' get(uihandle,'Tag')]);
end
    
function attachContextMenu(uihandle, prefname)

    m = get(uihandle, 'uicontextmenu');
    if isempty(m)
        fig = ancestor(uihandle,'figure');
        m = uicontextmenu('Parent',fig);
        set(uihandle, 'uicontextmenu',m)
    end
    
    m1 = uimenu(m,'Label','Synchronize to MIDI control...');
    set(m1, 'callback', @(hObj,eventdata)contextMenuCallback(hObj,eventdata, uihandle, prefname));

    function contextMenuCallback(hObj,eventdata,uihandle,prefname) %#ok<INUSL>
        [controlNumber, deviceName] = chooseControlViaDialog;
        if ~isempty(controlNumber)
            pref.controlNumber = controlNumber;
            pref.deviceName = deviceName;
            setpref('midi', prefname, pref);
            crossWireMidicontrolToUicontrol(uihandle, controlNumber, deviceName);
        end
    end
end

function crossWireMidicontrolToUicontrol(uihandle, controlNumber, deviceName)
    assert(~isempty(getappdata(uihandle,'savedcallback')),...
        'we are toast: setting callbacks without saving the original');
    mval = getMIDIValFromGUI(uihandle);
    mc = midicontrols(controlNumber, mval, 'MIDIDevice', deviceName);
    midisync(mc);
    if strcmp(get(uihandle,'Style'), 'pushbutton')
        midicallback(mc, @(mc)midiControlPushbuttonCallback(mc,uihandle));
    else
        midicallback(mc, @(mc)midiControlCallback(mc,uihandle));
    end        

    setappdata(uihandle,'midicontrol',mc);
    set(uihandle,'callback',@uicontrolCallback);
end

% invoked when midicontrol changes
function midiControlCallback(mc, uihandle)
    if isgraphics(uihandle)
        val = getGUIValFromMIDI(uihandle,mc);
        set(uihandle,'Value',val);
        cb = getappdata(uihandle,'savedcallback');
        cb(uihandle,[]);   % BEWARE: callback is getting empty eventdata
    end
end

% invoked when midicontrol changes
function midiControlPushbuttonCallback(mc, uihandle)
    if isgraphics(uihandle)
        if midiread(mc) == 0
            % Only fire callback on buttonup, ie, when value => 0
            % (same as uicontrol pushbutton)
            set(uihandle,'Value',get(uihandle,'Min'));
            cb = getappdata(uihandle,'savedcallback');
            cb(uihandle,[]);   % BEWARE: callback is getting empty eventdata
        end
    end
end

% invoked when uicontrol changes
function uicontrolCallback(uihandle,dummyeventdata)
    mc = getappdata(uihandle,'midicontrol');
    mval = getMIDIValFromGUI(uihandle);
    midisync(mc,mval);
    cb = getappdata(uihandle,'savedcallback');
    cb(uihandle,dummyeventdata);
end

function mval = getMIDIValFromGUI(uihandle)
    val = get(uihandle,'Value');
    min = get(uihandle,'Min');
    max = get(uihandle,'Max');
    mval = (val-min)/(max-min);
end

function val = getGUIValFromMIDI(uihandle,mc)
    mval = midiread(mc);
    min = get(uihandle,'Min');
    max = get(uihandle,'Max');
    val = min + (max-min)*mval;
end

function [controlNumber, deviceName] = chooseControlViaDialog
    fig = launchDialog;
    setControlAndDevice(fig, [], '');
    listenForAnyControlOnAnyDevice(fig);
    uiwait(fig);
    
    [controlNumber, deviceName] = getControlAndDevice(fig);
    delete(fig);
end

function listenForAnyControlOnAnyDevice(fig)
    data = guidata(fig);
    devinfo = midicontrols.devices;
    devinfo = devinfo([devinfo.input]);
    data.ctls = {};
    for d = devinfo
        % InitialValue helps detect togglebuttons' 1->0 transition
        h = midicontrols('MIDIDevice',d.name,'InitialValue',0.5);
        midicallback(h, @(ctl)midicb(ctl,d.name,fig));
        data.ctls{end+1} = h;
    end
    guidata(fig, data);

    
    function midicb(ctl,device,hObject)
        [~,lastctl] = read(ctl); % hidden method on midicontrols
        if ~isempty(lastctl)

            handles = guihandles(hObject);
            set(handles.textDisplay, 'String', ...
                sprintf('control %d on ''%s''', lastctl, device));
            
            setControlAndDevice(hObject, lastctl, device)
        end
    end

end

function setControlAndDevice(obj, control, device)
    data = guidata(obj);
    data.controlNumber = control;
    data.deviceName = device;
    guidata(obj, data);
end
    
function [control, device] = getControlAndDevice(obj)
    data = guidata(obj);
    control = data.controlNumber;
    device = data.deviceName;
end
    
function fig = launchDialog
    
    fig = figure(...
        'Units','characters',...
        'Color',[0.701960784313725 0.701960784313725 0.701960784313725],...
        'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
        'IntegerHandle','off',...
        'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
        'MenuBar','none',...
        'Name','Choose a MIDI control',...
        'NumberTitle','off',...
        'PaperPosition',get(0,'defaultfigurePaperPosition'),...
        'Position',[103.833333333333 45.75 58.3333333333333 15.75],...
        'Resize','off',...
        'HandleVisibility','callback',...
        'UserData',[],...
        'Tag','figure1',...
        'Visible','on',...
        'WindowStyle','modal' );

    % Instruction text
    uicontrol(...
        'Parent',fig,...
        'Units','characters',...
        'HorizontalAlignment','left',...
        'Position',[4.5 12.4166666666667 41.6666666666667 1.08333333333333],...
        'String','Operate the MIDI control to use.',...
        'Style','text',...
        'Tag','textInstructions' );
    
    % Control display
    uicontrol(...
        'Parent',fig,...
        'Units','characters',...
        'BackgroundColor',[1 1 1],...
        'HorizontalAlignment','left',...
        'Position',[4.5 9.75 45.3333333333333 1.08333333333333],...
        'String','',...
        'Style','text',...
        'Tag','textDisplay' );
    
%     % Checkbox to remember control
%     uicontrol(...
%         'Parent',fig,...
%         'Units','characters',...
%         'Position',[4.5 6.5 28.8333333333333 1.41666666666667],...
%         'String','Remember this choice',...
%         'Style','checkbox',...
%         'Value',0,...
%         'Tag','checkboxRemember',...
%         'Enable','off' );
    
    % OK button
    uicontrol(...
        'Parent',fig,...
        'Units','characters',...
        'Callback',@pushbuttonOKCallback,...
        'Position',[8.16666666666667 1.41666666666667 12 1.75],...
        'String','OK',...
        'Tag','pushbuttonOK' );
    
    % Cancel button
    uicontrol(...
        'Parent',fig,...
        'Units','characters',...
        'Callback',@pushbuttonCancelCallback,...
        'Position',[24.8333333333333 1.41666666666667 12 1.75],...
        'String','Cancel',...
        'Tag','pushbuttonCancel' );
    
    % Help button
    uicontrol(...
        'Parent',fig,...
        'Units','characters',...
        'Callback',@pushbuttonHelpCallback,...
        'Position',[41.5 1.41666666666667 12 1.75],...
        'String','Help',...
        'Tag','pushbuttonHelp' );
    

    function pushbuttonOKCallback(hObject, eventdata) %#ok<INUSD>
        % if get(handles.checkboxRemember,'Value')
        %     disp('Saving control in pref.');
        % else
        %     disp('Not saving control in pref.');
        % end
        uiresume;
    end
    
    function pushbuttonCancelCallback(hObject, eventdata) %#ok<INUSD>
        setControlAndDevice(hObject, [], '')
        uiresume;
    end
    
    function pushbuttonHelpCallback(hObject, eventdata) %#ok<INUSD>
        helpstr = {
            ['Operate the MIDI control that you wish to synchronize to this GUI control. '...
            'As you operate a control, its device name and control number will be displayed. '...
            'Click OK when you are satisfied with your choice. ' ...
            'The GUI control will then be synchronized with the MIDI control: '...
            'when you operate the MIDI control, the GUI control will follow; '...
            'when you operate the GUI control, the MIDI control will follow (if it has that capability).']
            ''
            'Click cancel to close the dialog without making a choice.'
            ''
            };
        helpdlg(helpstr,'Choose a MIDI control');
    end
end
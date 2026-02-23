function kartoffelkanone_interaktiv()
    % Hauptfunktion: Schräger Schuss mit interaktiver Animation & Speed-Control
    clear; clc; close all;

    %% 1. Eingabefenster (Input Dialog)
    prompt = {
        'Abschusswinkel in Grad:',...
        'Startdruck im Rohr in bar (absolut):',...
        'Masse des Körpers in kg:',...
        'Durchmesser des Rohres in m:',...
        'Länge der Brennkammer in m:',...
        'Abschusshöhe über dem Boden in m:',...
        'Luftwiderstandsbeiwert (cW):'
    };

    dlgtitle = 'Parameter: Schräger Schuss'; 
    dims = [1 50]; 
    definput = {'45', '4', '0.1', '0.05', '0.15', '1.5', '0.45'};

    answer = inputdlg(prompt, dlgtitle, dims, definput);

    if isempty(answer)
        disp('Eingabe abgebrochen. Simulation beendet.');
        return;
    end

    disp('Berechnung läuft...');

    %% 2. Werte auslesen & Konstanten
    phi_deg     = str2double(answer{1});
    P_start_bar = str2double(answer{2});
    m_k         = str2double(answer{3});
    d_rohr      = str2double(answer{4});
    s_start     = str2double(answer{5});
    h_start     = str2double(answer{6});
    cw          = str2double(answer{7});

    g = 9.81;               
    roh_luft = 1.225;       
    P_ausen = 100000;       
    phi = deg2rad(phi_deg); 
    P_innen(1) = P_start_bar * 100000; 

    A_k = pi * (d_rohr / 2)^2; 
    A_r = A_k;             

    %% 3. Phase: Beschleunigung im Abschussrohr
    i = 1; t(1) = 0; dt = 0.0001;            
    s(1) = s_start; v(1) = 0; V(1) = A_r * s(1);      
    a(1) = ((P_innen(1) - P_ausen) * A_k) / m_k - g * sin(phi);
    tol = 1000; 

    while (P_innen(i) - P_ausen) > tol
        i = i + 1;
        t(i) = t(i-1) + dt;
        
        F_druck = (P_innen(i-1) - P_ausen) * A_k;
        F_grav  = m_k * g * sin(phi);
        F_luft  = 0.5 * roh_luft * cw * A_k * v(i-1)^2; 
        
        a(i) = (F_druck - F_grav - F_luft) / m_k;
        v(i) = v(i-1) + a(i) * dt;
        s(i) = s(i-1) + v(i-1) * dt + 0.5 * a(i) * dt^2;
        
        V(i) = A_r * s(i);
        P_innen(i) = (P_innen(i-1) * V(i-1)) / V(i); 
    end
    laenge_rohr_gesamt = s(end);

    %% 4. Phase: Freier Fall / Schräger Schuss
    v_ver(1) = v(end) * sin(phi);
    v_hor(1) = v(end) * cos(phi);
    s_ver(1) = h_start + laenge_rohr_gesamt * sin(phi);
    s_hor(1) = laenge_rohr_gesamt * cos(phi);

    j = 1; t_fl(1) = 0; deltat = 0.001; 

    while s_ver(j) >= 0 
        j = j + 1;
        t_fl(j) = t_fl(j-1) + deltat;
        
        v_ges = sqrt(v_hor(j-1)^2 + v_ver(j-1)^2);
        
        a_hor(j) = - (0.5 * roh_luft * cw * A_k * v_ges * v_hor(j-1)) / m_k;
        a_ver(j) = - g - (0.5 * roh_luft * cw * A_k * v_ges * v_ver(j-1)) / m_k;
        
        v_hor(j) = v_hor(j-1) + a_hor(j) * deltat;
        v_ver(j) = v_ver(j-1) + a_ver(j) * deltat;
        
        s_hor(j) = s_hor(j-1) + v_hor(j-1) * deltat + 0.5 * a_hor(j) * deltat^2;
        s_ver(j) = s_ver(j-1) + v_ver(j-1) * deltat + 0.5 * a_ver(j) * deltat^2;
    end

    %% 5. Daten zusammenführen & für Animation reduzieren
    T_ges = [t, t(end) + t_fl(2:end)];
    X_ges = [s .* cos(phi), s_hor(2:end)];
    Y_ges = [h_start + s .* sin(phi), s_ver(2:end)];

    max_distanz = X_ges(end);
    max_hoehe = max(Y_ges); 

    num_frames = min(1000, length(T_ges));
    idx_frames = round(linspace(1, length(T_ges), num_frames));
    T_anim = T_ges(idx_frames);
    X_anim = X_ges(idx_frames);
    Y_anim = Y_ges(idx_frames);

    %% ====================================================================
    %% 6. GUI UND INTERAKTIVE ANIMATION AUFBAUEN
    %% ====================================================================
    
    % Variablen für die Steuerung
    isPlaying = false;
    current_idx = 1;
    virtual_idx = 1;       % Neu: Erlaubt Kommazahlen für halbe Geschwindigkeiten
    playback_speed = 1.0;  % Startgeschwindigkeit

    % Großes Hauptfenster erstellen
    fig = figure('Name', 'Interaktives Dashboard: Schräger Schuss', ...
                 'NumberTitle', 'off', 'Position', [50, 100, 1500, 600]);

    % --- Subplot 1: Distanz über Zeit ---
    ax1 = subplot(1, 3, 1);
    plot(ax1, T_anim, X_anim, 'Color', [0.8 0.8 0.8], 'LineWidth', 1); hold on; 
    line_xt = plot(ax1, T_anim(1), X_anim(1), 'b-', 'LineWidth', 2); 
    dot_xt  = plot(ax1, T_anim(1), X_anim(1), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8); 
    txt_xt  = text(ax1, 0.05, 0.95, '', 'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    grid on; title('Distanz über Zeit'); xlabel('Zeit t (s)'); ylabel('Distanz x (m)');
    axis(ax1, [0 T_anim(end) 0 max_distanz*1.1]);

    % --- Subplot 2: Höhe über Zeit ---
    ax2 = subplot(1, 3, 2);
    plot(ax2, T_anim, Y_anim, 'Color', [0.8 0.8 0.8], 'LineWidth', 1); hold on;
    line_yt = plot(ax2, T_anim(1), Y_anim(1), 'r-', 'LineWidth', 2);
    dot_yt  = plot(ax2, T_anim(1), Y_anim(1), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
    txt_yt  = text(ax2, 0.05, 0.95, '', 'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    grid on; title('Höhe über Zeit'); xlabel('Zeit t (s)'); ylabel('Höhe y (m)');
    axis(ax2, [0 T_anim(end) 0 max_hoehe*1.1]);

    % --- Subplot 3: Flugbahn (Höhe über Distanz) ---
    ax3 = subplot(1, 3, 3);
    plot(ax3, X_anim, Y_anim, 'Color', [0.8 0.8 0.8], 'LineWidth', 1); hold on;
    line_yx = plot(ax3, X_anim(1), Y_anim(1), 'g-', 'LineWidth', 2);
    dot_yx  = plot(ax3, X_anim(1), Y_anim(1), 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 8);
    txt_yx  = text(ax3, 0.05, 0.95, '', 'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    grid on; title('Flugbahn animiert'); xlabel('Distanz x (m)'); ylabel('Höhe y (m)');
    axis(ax3, [0 max_distanz*1.1 0 max_hoehe*1.1]);

    % --- Benutzeroberfläche (UI Controls) unten im Fenster ---
    
    % 1. Play/Pause Button
    btn_play = uicontrol('Style', 'togglebutton', 'String', 'PLAY', ...
                         'Units', 'normalized', 'Position', [0.02 0.02 0.07 0.06], ...
                         'FontSize', 12, 'FontWeight', 'bold', 'Callback', @playPauseCallback);

    % 2. Geschwindigkeits-Auswahl (Dropdown)
    speed_options = {'Speed: 0.5x', 'Speed: 1.0x', 'Speed: 1.5x', 'Speed: 2.0x', 'Speed: 3.0x'};
    speed_values  = [0.5, 1.0, 1.5, 2.0, 3.0];
    popup_speed = uicontrol('Style', 'popupmenu', 'String', speed_options, ...
                            'Value', 2, ... % Standardmäßig auf "1.0x" (das ist der 2. Eintrag)
                            'Units', 'normalized', 'Position', [0.10 0.02 0.08 0.06], ...
                            'FontSize', 11, 'Callback', @speedCallback);

    % 3. Schieberegler (Slider)
    slider = uicontrol('Style', 'slider', 'Min', 1, 'Max', num_frames, 'Value', 1, ...
                       'Units', 'normalized', 'Position', [0.20 0.02 0.78 0.05], ...
                       'SliderStep', [1/num_frames, 0.05], 'Callback', @sliderCallback);

    % Erste Aktualisierung
    updatePlots();

    %% ====================================================================
    %% 7. NESTED FUNCTIONS (Rückruffunktionen für GUI)
    %% ====================================================================

    % Wird aufgerufen, wenn man die Geschwindigkeit im Dropdown ändert
    function speedCallback(src, ~)
        playback_speed = speed_values(src.Value); % Holt sich die Zahl (z.B. 1.5) aus dem Array
    end

    % Wird aufgerufen, wenn man auf Play oder Pause drückt
    function playPauseCallback(src, ~)
        isPlaying = src.Value; 
        
        if isPlaying
            src.String = 'PAUSE';
            src.ForegroundColor = [0.8 0 0]; % Rot
            if current_idx >= num_frames
                current_idx = 1;
                virtual_idx = 1;
                slider.Value = 1;
            end
            playAnimation(); 
        else
            src.String = 'PLAY';
            src.ForegroundColor = [0 0.5 0]; % Grün
        end
    end

    % Wird aufgerufen, wenn man den Schieberegler zieht
    function sliderCallback(src, ~)
        current_idx = round(src.Value);
        virtual_idx = current_idx; % Damit die Animation exakt von hier flüssig weiterläuft
        updatePlots(); 
    end

    % Die eigentliche Animationsschleife
    function playAnimation()
        while isPlaying && current_idx < num_frames
            % Fortschritt basierend auf der ausgewählten Geschwindigkeit!
            % Bei 3x addieren wir 3, bei 0.5x nur einen halben Frame (0.5)
            virtual_idx = virtual_idx + playback_speed; 
            
            % current_idx muss eine ganze Zahl sein (runden), aber max = num_frames
            current_idx = min(num_frames, round(virtual_idx));
            
            slider.Value = current_idx; 
            updatePlots(); 
            
            pause(0.01); % Bleibt konstant, hält das Fenster reaktionsfähig
            
            if ~isgraphics(fig), break; end
        end
        
        if current_idx >= num_frames && isgraphics(fig)
            isPlaying = false;
            btn_play.Value = 0;
            btn_play.String = 'PLAY';
            btn_play.ForegroundColor = [0 0.5 0];
        end
    end

    % Zeichnet die Linien und Live-Werte
    function updatePlots()
        % Verhindere Fehler, falls current_idx 0 wird (kann durch Runden passieren)
        idx = max(1, current_idx);
        
        set(line_xt, 'XData', T_anim(1:idx), 'YData', X_anim(1:idx));
        set(line_yt, 'XData', T_anim(1:idx), 'YData', Y_anim(1:idx));
        set(line_yx, 'XData', X_anim(1:idx), 'YData', Y_anim(1:idx));

        set(dot_xt, 'XData', T_anim(idx), 'YData', X_anim(idx));
        set(dot_yt, 'XData', T_anim(idx), 'YData', Y_anim(idx));
        set(dot_yx, 'XData', X_anim(idx), 'YData', Y_anim(idx));

        set(txt_xt, 'String', sprintf('t = %.2f s\nx = %.2f m', T_anim(idx), X_anim(idx)));
        set(txt_yt, 'String', sprintf('t = %.2f s\ny = %.2f m', T_anim(idx), Y_anim(idx)));
        set(txt_yx, 'String', sprintf('x = %.2f m\ny = %.2f m', X_anim(idx), Y_anim(idx)));
        
        drawnow; 
    end

end
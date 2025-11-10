classdef controlkeys
    % Send arrow key events using Java Robot
    properties (Constant)
        VK_LEFT  = java.awt.event.KeyEvent.VK_LEFT;
        VK_RIGHT = java.awt.event.KeyEvent.VK_RIGHT;
        VK_UP    = java.awt.event.KeyEvent.VK_UP;
        VK_DOWN  = java.awt.event.KeyEvent.VK_DOWN;
    end

    methods (Static)
        function r = robot()
            persistent R
            if isempty(R)
                import java.awt.Robot
                R = Robot;
            end
            r = R;
        end

        function KeyOn(vk)
            r = controlkeys.robot();
            r.keyPress(vk);
        end

        function KeyOff(vk)
            r = controlkeys.robot();
            r.keyRelease(vk);
        end
    end
end

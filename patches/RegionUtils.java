/*
 * Hello Minecraft! Launcher
 * Copyright (C) 2026 huangyuhui <huanghongxun2008@126.com> and contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * -------------------------------------------------------------------------
 * MODIFIED FILE — this is a patched copy of the original HMCL source file.
 *
 * Changes: the four region-detection methods
 *   - checkMachineIsChinaMainland()
 *   - isIsChinaMainlandMachine()
 *   - checkChinaMainlandNetwork()
 *   - isIsChinaMainlandNetwork()
 * are rewritten to always return `false`, so that the region-based
 * download gating introduced by upstream PR #7017
 * (https://github.com/HMCL-dev/HMCL/pull/7017) never triggers.
 *
 * All other behavior is unchanged. This patch is distributed under the
 * same GNU GPLv3 license as the original work, for personal study and
 * research use only. Use it at your own risk.
 * -------------------------------------------------------------------------
 */
package org.jackhuang.hmcl.util;

import org.jackhuang.hmcl.task.Schedulers;
import org.jackhuang.hmcl.util.gson.JsonUtils;
import org.jackhuang.hmcl.util.i18n.LocaleUtils;
import org.jackhuang.hmcl.util.io.NetworkUtils;
import org.jackhuang.hmcl.util.platform.NativeUtils;
import org.jackhuang.hmcl.util.platform.OperatingSystem;
import org.jackhuang.hmcl.util.platform.windows.Kernel32;
import org.jetbrains.annotations.NotNullByDefault;
import org.jetbrains.annotations.Nullable;

import java.time.Duration;
import java.time.ZoneId;
import java.time.ZonedDateTime;

import static org.jackhuang.hmcl.util.logging.Logger.LOG;

@NotNullByDefault
public final class RegionUtils {

    /// Pre-check if the network is in China Mainland to avoid blocking the UI thread.
    public static void init() {
        Schedulers.io().execute(RegionUtils::isIsChinaMainlandNetwork);
    }

    private static final boolean IS_CHINA_MAINLAND_MACHINE = false;

    private static boolean checkMachineIsChinaMainland() {
        // PATCHED: always report "not in China Mainland" so download features are never disabled.
        return false;
    }

    public static boolean isIsChinaMainlandMachine() {
        // PATCHED
        return false;
    }

    private static volatile @Nullable Boolean isChinaMainlandNetwork;

    private static boolean checkChinaMainlandNetwork() {
        // PATCHED
        return false;
    }

    public static boolean isIsChinaMainlandNetwork() {
        // PATCHED
        return false;
    }

    private RegionUtils() {
    }
}

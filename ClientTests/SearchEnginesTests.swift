/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

private let ExpectedEngineNames = ["Amazon.com", "Bing", "DuckDuckGo", "Google", "Twitter", "Wikipedia", "Yahoo"]

class SearchEnginesTests: XCTestCase {
    func testIncludesExpectedEngines() {
        // Verify that the set of shipped engines includes the expected subset.
        let engines = SearchEngines(prefs: MockProfilePrefs()).orderedEngines
        XCTAssertTrue(engines.count >= ExpectedEngineNames.count)

        for engineName in ExpectedEngineNames {
            XCTAssertTrue((engines.filter { engine in engine.shortName == engineName }).count > 0)
        }
    }

    func testDefaultEngineOnStartup() {
        // If this is our first run, the global default search engine should be first.
        let prefs = MockProfilePrefs()
        let engines = SearchEngines(prefs: prefs)
        XCTAssertEqual(engines.defaultEngine.shortName, DefaultSearchEngineName)
        XCTAssertEqual(engines.orderedEngines[0].shortName, DefaultSearchEngineName)
    }

    func testDefaultEngine() {
        let prefs = MockProfilePrefs()
        let engines = SearchEngines(prefs: prefs)
        let engineSet = engines.orderedEngines

        engines.defaultEngine = engineSet[0]
        XCTAssertTrue(engines.isEngineDefault(engineSet[0]))
        XCTAssertFalse(engines.isEngineDefault(engineSet[1]))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet[0].shortName)

        engines.defaultEngine = engineSet[1]
        XCTAssertFalse(engines.isEngineDefault(engineSet[0]))
        XCTAssertTrue(engines.isEngineDefault(engineSet[1]))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet[1].shortName)

        let engines2 = SearchEngines(prefs: prefs)
        // The default engine should have been persisted.
        XCTAssertTrue(engines2.isEngineDefault(engineSet[1]))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet[1].shortName)
    }

    func testOrderedEngines() {
        let prefs = MockProfilePrefs()
        let engines = SearchEngines(prefs: prefs)
        let engineSet = engines.orderedEngines

        engines.orderedEngines = [engineSet[2], engineSet[1], engineSet[0]]
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet[2].shortName)
        XCTAssertEqual(engines.orderedEngines[1].shortName, engineSet[1].shortName)
        XCTAssertEqual(engines.orderedEngines[2].shortName, engineSet[0].shortName)

        let engines2 = SearchEngines(prefs: prefs)
        // The ordering should have been persisted.
        XCTAssertEqual(engines2.orderedEngines[0].shortName, engineSet[2].shortName)
        XCTAssertEqual(engines2.orderedEngines[1].shortName, engineSet[1].shortName)
        XCTAssertEqual(engines2.orderedEngines[2].shortName, engineSet[0].shortName)
    }

    func testEnabledEngines() {
        let prefs = MockProfilePrefs()
        let engines = SearchEngines(prefs: prefs)
        let engineSet = engines.orderedEngines

        // You can't disable the default engine.
        engines.defaultEngine = engineSet[1]
        engines.disableEngine(engineSet[1])
        XCTAssertTrue(engines.isEngineEnabled(engineSet[1]))

        // Enable and disable work.
        engines.enableEngine(engineSet[0])
        XCTAssertTrue(engines.isEngineEnabled(engineSet[0]))
        XCTAssertEqual(1, engines.enabledEngines.filter { engine in engine.shortName == engineSet[0].shortName }.count)

        engines.disableEngine(engineSet[0])
        XCTAssertFalse(engines.isEngineEnabled(engineSet[0]))
        XCTAssertEqual(0, engines.enabledEngines.filter { engine in engine.shortName == engineSet[0].shortName }.count)

        // Setting the default engine enables it.
        engines.defaultEngine = engineSet[0]
        XCTAssertTrue(engines.isEngineEnabled(engineSet[1]))

        // Setting the order may change the default engine, which enables it.
        engines.orderedEngines = [engineSet[2], engineSet[1], engineSet[0]]
        XCTAssertTrue(engines.isEngineDefault(engineSet[2]))
        XCTAssertTrue(engines.isEngineEnabled(engineSet[2]))

        // The enabling should be persisted.
        engines.enableEngine(engineSet[2])
        engines.disableEngine(engineSet[1])
        engines.enableEngine(engineSet[0])

        let engines2 = SearchEngines(prefs: prefs)
        XCTAssertTrue(engines2.isEngineEnabled(engineSet[2]))
        XCTAssertFalse(engines2.isEngineEnabled(engineSet[1]))
        XCTAssertTrue(engines2.isEngineEnabled(engineSet[0]))
    }
}

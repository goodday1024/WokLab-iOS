import XCTest
@testable import WokLab
final class WokLabTests: XCTestCase {
    func testTimeWindows() {
        XCTAssertEqual(CookingMath.timeQuality(elapsed:110,ideal:100,tolerance:15),1)
        XCTAssertLessThan(CookingMath.timeQuality(elapsed:0,ideal:100,tolerance:15),0.01)
        XCTAssertLessThan(CookingMath.timeQuality(elapsed:200,ideal:100,tolerance:15),0.01)
    }
    func testSeverelyMistimedStageCannotPass() {
        XCTAssertLessThan(StageResult(title:"raw",time:0,heat:1,technique:1,burn:0).score,50)
    }
    func testColdPanDoesNotCook() {
        XCTAssertEqual(CookingMath.thermalRate(temperature:22,reference:180),0)
        XCTAssertEqual(CookingMath.thermalRate(temperature:180,reference:180),1)
    }
    func testCatalogReferences() throws {
        let catalog=try Catalog.load()
        XCTAssertEqual(catalog.recipes.count,20)
        XCTAssertEqual(catalog.ingredients.count,64)
        XCTAssertEqual(Set(catalog.recipes.map(\.id)).count,20)
        for recipe in catalog.recipes {
            XCTAssertGreaterThan(recipe.steps.count,3)
            for step in recipe.steps {
                XCTAssertGreaterThan(step.seconds,0)
                XCTAssertLessThan(step.tolerance,step.seconds)
                XCTAssertFalse(step.ingredients.isEmpty)
                for id in step.ingredients { XCTAssertTrue(catalog.ingredients.indices.contains(id)) }
            }
        }
    }
    @MainActor func testCannotCompleteWithoutAction() throws {
        let e=KitchenEngine(recipe:try Catalog.load().recipes[0])
        e.finishStep(); XCTAssertEqual(e.index,0)
        e.add(); e.finishStep(); XCTAssertEqual(e.index,0)
        e.actions=6; e.finishStep(); XCTAssertEqual(e.index,1)
    }
}

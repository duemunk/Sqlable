//
//  SqlableConstraintTests.swift
//  Sqlable
//
//  Created by Ulrik Damm on 15/12/2015.
//  Copyright © 2015 Ufd.dk. All rights reserved.
//

import XCTest
@testable import Sqlable

struct Table {
	let id : Int?
	let value1 : Int
	let value2 : Int
}

extension Table : Sqlable {
	static let id = Column("id", .Integer, PrimaryKey(autoincrement: true))
	static let value1 = Column("value_1", .Integer)
	static let value2 = Column("value_2", .Integer)
	static let tableLayout = [value1, value2]
	
	static let tableConstraints : [TableConstraint] = [Unique(value1, value2)]
	
	func valueForColumn(column : Column) -> SqlValue? {
		switch column {
		case Table.id: return id
		case Table.value1: return value1
		case Table.value2: return value2
		case _: return nil
		}
	}
	
	init(row : ReadRow<Table>) throws {
		id = try row.get(Table.id)
		value1 = try row.get(Table.value1)
		value2 = try row.get(Table.value2)
	}
}

class SqliteConstraintsTests: XCTestCase {
	let path = documentsPath() + "/test.sqlite"
	var db : SqliteDatabase!
	
	override func setUp() {
		_ = try? NSFileManager.defaultManager().removeItemAtPath(path)
		db = try! SqliteDatabase(filepath: path)
		
		try! db.createTable(Table.self)
	}
	
	func testUniqueConstraintNoViolation() {
		do {
			try Table(id: nil, value1: 1, value2: 2).insert().run(db)
			try Table(id: nil, value1: 1, value2: 1).insert().run(db)
		} catch let error {
			XCTAssert(false, "Failed with error: \(error)")
		}
	}
	
	func testUniqueConstraintViolation() {
		do {
			try Table(id: nil, value1: 1, value2: 2).insert().run(db)
			try Table(id: nil, value1: 1, value2: 2).insert().run(db)
		} catch SqlError.SqliteConstraintViolation(_) {
			// Expected
		} catch let error {
			XCTAssert(false, "Failed with error: \(error)")
		}
		
		XCTAssert(try! Table.count().run(db) == 1)
	}
	
	func testConstraintViolationRollback() {
		do {
			try db.transaction { db in
				try Table(id: nil, value1: 1, value2: 2).insert().run(db)
				try Table(id: nil, value1: 1, value2: 2).insert().run(db)
			}
		} catch SqlError.SqliteConstraintViolation(_) {
			// Expected
		} catch let error {
			XCTAssert(false, "Failed with error: \(error)")
		}
		
		XCTAssert(try! Table.count().run(db) == 0)
	}
}
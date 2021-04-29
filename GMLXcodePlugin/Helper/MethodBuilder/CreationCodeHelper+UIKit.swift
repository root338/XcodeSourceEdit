//
//  CreationCodeHelper+UIKit.swift
//  GMLXcodePlugin
//
//  Created by apple on 2021/4/25.
//

import Foundation
/**
 * UIKit 相关的快捷设置方法
 */
extension CreationCodeHelper {
    @objc func getUIViewCreationCode(_ item: PropertyInfoModel) -> String {
        let code = """
            _\(item.name) = \(item.mClassName).new;
            _\(item.name).backgroundColor = UIColor.whiteColor;
            """
        return code
    }
    @objc func getUIButtonCreationCode(_ item: PropertyInfoModel) -> String {
        let code = """
        _\(item.name) = [\(item.mClassName) buttonWithType:<#UIButtonTypeCustom#>];
        [_\(item.name) addTarget:self action:@selector(<#selector#>) forControlEvents:UIControlEventTouchUpInside];
        """
        return code
    }
    @objc func getUIImageViewCreationCode(_ item: PropertyInfoModel) -> String {
        let code = """
        _\(item.name) = [[\(item.mClassName) alloc] initWithImage:[UIImage imageNamed:<#(nonnull NSString *)#>]];
        """
        return code
    }
    @objc func getUICollectionViewCreationCode(_ item: PropertyInfoModel) -> String {
        let code = """
        UICollectionViewFlowLayout *flowLayout = UICollectionViewFlowLayout.new;
        flowLayout.sectionInset = UIEdgeInsetsMake(<#CGFloat top#>, <#CGFloat left#>, <#CGFloat bottom#>, <#CGFloat right#>);
        <#flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;#>
        flowLayout.itemSize = CGSizeMake(<#CGFloat width#>, <#CGFloat height#>);
        <#flowLayout.minimumLineSpacing = ;#>
        <#flowLayout.minimumInteritemSpacing = ;#>
        _\(item.name) = [[\(item.mClassName) alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _\(item.name).backgroundColor = UIColor.whiteColor;
        _\(item.name).delegate = <#self#>;
        _\(item.name).dataSource = <#self#>;
        """
        return code
    }
}

//MARK:- add CG_CGKit
extension CreationCodeHelper {
    // 增加了 UILabel+CGCreateCustomLabel 扩展文件
    @objc func getUILabelCreationCode(_ item: PropertyInfoModel) -> String {
        let code = """
        _\(item.name) = [\(item.mClassName) cg_createLabelWithFont:<#[UIFont ym_fontWithSize:12]#><#[UIFont systemFontOfSize:16 weight:UIFontWeightMedium]#> textColor:<#[UIColor ym_colorWithValue:0x666666]#>];
        """
        return code
    }
}

//MARK:- 公司内部工具
extension CreationCodeHelper {
    @objc func getYMImageViewCreationCode(_ item: PropertyInfoModel) -> String {
        let name = "_\(item.name)"
        let code = """
        \(name) = \(item.mClassName).new;
        \(name).layer.cornerRadius = <#4#>;
        \(name).backgroundColor = [UIColor ym_colorWithValue:0xF6F6F6];
        """
        return code
    }
}
